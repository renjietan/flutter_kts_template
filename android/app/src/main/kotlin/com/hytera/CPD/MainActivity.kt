package com.hytera.cpd

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * 注钥枪 USB Host 通信（Android 端）。
 *
 * 设备为 Vendor Specific Class（bInterfaceClass=255），接口号 2，两个 Bulk 端点：
 *   - EP5 IN  (0x85)：接收注钥枪回传数据
 *   - EP4 OUT (0x04)：向注钥枪发送数据
 *
 * 通过 MethodChannel（方法调用）与 EventChannel（数据流）暴露给 Dart 层。
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "KeyLoaderUsbHost"
        private const val METHOD_CHANNEL = "com.hytera.cpd/usb_host"
        private const val EVENT_CHANNEL = "com.hytera.cpd/usb_host/events"
        private const val EVENT_CHANNEL_DISCONNECT =
            "com.hytera.cpd/usb_host/disconnected"
        private const val ACTION_USB_PERMISSION = "com.hytera.cpd.USB_PERMISSION"

        private const val TARGET_VENDOR_ID = 0x1D6B
        private const val TARGET_PRODUCT_ID = 0x0104
        private const val TARGET_INTERFACE_INDEX = 2
        private const val READ_BUFFER_SIZE = 512
        private const val READ_TIMEOUT_MS = 500
        private const val WRITE_TIMEOUT_MS = 3000
    }

    private var usbManager: UsbManager? = null
    private var connection: UsbDeviceConnection? = null
    private var device: UsbDevice? = null
    private var inEndpoint: UsbEndpoint? = null
    private var outEndpoint: UsbEndpoint? = null
    private var usbInterface: UsbInterface? = null

    private var readThread: Thread? = null
    private val readRunning = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null
    private var disconnectEventSink: EventChannel.EventSink? = null

    private var permissionResult: MethodChannel.Result? = null

    private val usbPermissionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_USB_PERMISSION) {
                val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                val result = permissionResult
                permissionResult = null
                result?.success(granted)
            }
        }
    }

    private val usbDetachedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != UsbManager.ACTION_USB_DEVICE_DETACHED) return
            @Suppress("DEPRECATION")
            val detached = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
            val current = device
            if (detached == null || current == null || detached.deviceName == current.deviceName) {
                notifyDisconnected()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        registerUsbPermissionReceiver()
        registerUsbDetachedReceiver()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasPermission())
                    "requestPermission" -> requestPermission(result)
                    "connect" -> result.success(connect())
                    "write" -> {
                        val bytes = (call.arguments as? ByteArray) ?: ByteArray(0)
                        writeBytes(bytes, result)
                    }
                    "disconnect" -> {
                        disconnect()
                        result.success(null)
                    }
                    "isConnected" -> result.success(isConnected())
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_DISCONNECT)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    disconnectEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    disconnectEventSink = null
                }
            })
    }

    override fun onDestroy() {
        disconnect()
        unregisterReceiver(usbPermissionReceiver)
        unregisterReceiver(usbDetachedReceiver)
        super.onDestroy()
    }

    // ------------------------------------------------------------------ 权限

    private fun findTargetDevice(): UsbDevice? {
        val manager = usbManager ?: return null
        for (candidate in manager.deviceList.values) {
            if (candidate.vendorId == TARGET_VENDOR_ID &&
                candidate.productId == TARGET_PRODUCT_ID
            ) {
                return candidate
            }
        }
        return null
    }

    private fun hasPermission(): Boolean {
        val target = findTargetDevice() ?: return false
        return usbManager?.hasPermission(target) == true
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val target = findTargetDevice()
        if (target == null) {
            result.success(false)
            return
        }
        if (usbManager?.hasPermission(target) == true) {
            result.success(true)
            return
        }
        permissionResult = result
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            Intent(ACTION_USB_PERMISSION),
            PendingIntent.FLAG_MUTABLE,
        )
        usbManager?.requestPermission(target, pendingIntent)
    }

    private fun registerUsbPermissionReceiver() {
        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbPermissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(usbPermissionReceiver, filter)
        }
    }

    private fun registerUsbDetachedReceiver() {
        val filter = IntentFilter(UsbManager.ACTION_USB_DEVICE_DETACHED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbDetachedReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(usbDetachedReceiver, filter)
        }
    }

    // ------------------------------------------------------------------ 连接

    private fun isConnected(): Boolean = connection != null

    private fun connect(): Boolean {
        try {
            disconnect()

            val target = findTargetDevice()
            if (target == null) {
                Log.w(TAG, "target device not found")
                return false
            }
            if (usbManager?.hasPermission(target) != true) {
                Log.w(TAG, "no usb permission")
                return false
            }

            Log.i(
                TAG,
                "device=${target.deviceName} vid=${target.vendorId} pid=${target.productId} " +
                    "ifaceCount=${target.interfaceCount}",
            )

            val conn = usbManager?.openDevice(target) ?: return false

            // 扫描所有接口，找“同时有 bulk IN 和 bulk OUT”的接口，优先 bInterfaceNumber==2。
            var chosenIface: UsbInterface? = null
            var chosenIn: UsbEndpoint? = null
            var chosenOut: UsbEndpoint? = null

            for (i in 0 until target.interfaceCount) {
                val iface = target.getInterface(i)
                Log.i(
                    TAG,
                    "iface[$i] num=${iface.id} class=${iface.interfaceClass} " +
                        "epCount=${iface.endpointCount}",
                )

                var tmpIn: UsbEndpoint? = null
                var tmpOut: UsbEndpoint? = null
                for (j in 0 until iface.endpointCount) {
                    val ep = iface.getEndpoint(j)
                    val dir = if (ep.direction == UsbConstants.USB_DIR_IN) "IN" else "OUT"
                    Log.i(
                        TAG,
                        "  ep[$j] addr=0x${ep.address.toString(16).padStart(2, '0')} " +
                            "$dir type=${ep.type} maxPkt=${ep.maxPacketSize}",
                    )
                    if (ep.type != UsbConstants.USB_ENDPOINT_XFER_BULK) continue
                    if (ep.direction == UsbConstants.USB_DIR_IN && tmpIn == null) {
                        tmpIn = ep
                    } else if (ep.direction == UsbConstants.USB_DIR_OUT && tmpOut == null) {
                        tmpOut = ep
                    }
                }

                if (tmpIn != null && tmpOut != null) {
                    if (chosenIface == null) {
                        chosenIface = iface
                        chosenIn = tmpIn
                        chosenOut = tmpOut
                    }
                    if (iface.id == TARGET_INTERFACE_INDEX) {
                        chosenIface = iface
                        chosenIn = tmpIn
                        chosenOut = tmpOut
                        break
                    }
                }
            }

            if (chosenIface == null || chosenIn == null || chosenOut == null) {
                conn.close()
                Log.w(TAG, "endpoint not found")
                return false
            }

            if (!conn.claimInterface(chosenIface, true)) {
                conn.close()
                Log.w(TAG, "claim interface failed")
                return false
            }

            device = target
            connection = conn
            usbInterface = chosenIface
            inEndpoint = chosenIn
            outEndpoint = chosenOut
            startReadThread()
            Log.i(
                TAG,
                "connected iface=${chosenIface.id} " +
                    "in=0x${chosenIn.address.toString(16).padStart(2, '0')} " +
                    "out=0x${chosenOut.address.toString(16).padStart(2, '0')}",
            )
            return true
        } catch (e: Exception) {
            Log.e(TAG, "connect error", e)
            disconnect()
            return false
        }
    }

    private fun writeBytes(data: ByteArray, result: MethodChannel.Result) {
        val ep = outEndpoint
        val conn = connection
        if (ep == null || conn == null) {
            result.success(-1)
            return
        }
        // 现在一次写入的是完整文件包，体积可能较大且可能包含敏感数据，
        // 因此只记录大小，不打印完整十六进制内容。
        Log.i(TAG, "write ${data.size} bytes")
        Thread {
            var written = -1
            try {
                written = conn.bulkTransfer(ep, data, data.size, WRITE_TIMEOUT_MS)
            } catch (e: Exception) {
                Log.e(TAG, "write error", e)
            }
            val finalWritten = written
            runOnUiThread { result.success(finalWritten) }
        }.start()
    }

    private fun startReadThread() {
        readRunning.set(true)
        readThread = Thread {
            val buffer = ByteArray(READ_BUFFER_SIZE)
            while (readRunning.get()) {
                val ep = inEndpoint
                val conn = connection
                if (ep == null || conn == null) break
                val length = try {
                    conn.bulkTransfer(ep, buffer, buffer.size, READ_TIMEOUT_MS)
                } catch (e: Exception) {
                    Log.e(TAG, "read error", e)
                    if (readRunning.get()) {
                        notifyDisconnected()
                    }
                    break
                }
                if (!readRunning.get()) break
                if (length < 0) {
                    notifyDisconnected()
                    break
                }
                if (length > 0) {
                    val chunk = buffer.copyOf(length)
                    try {
                        eventSink?.success(chunk)
                    } catch (_: Exception) {
                        // EventChannel 已取消，忽略
                    }
                }
            }
        }
        readThread?.start()
    }

    private fun notifyDisconnected() {
        try {
            disconnectEventSink?.success(true)
        } catch (_: Exception) {
            // EventChannel 已取消，忽略
        }
    }

    private fun disconnect() {
        readRunning.set(false)
        readThread?.let { thread ->
            if (thread !== Thread.currentThread()) {
                try {
                    thread.join(100)
                } catch (_: InterruptedException) {
                    // ignore
                }
            }
        }
        readThread = null

        connection?.let { conn ->
            usbInterface?.let { iface ->
                try {
                    conn.releaseInterface(iface)
                } catch (_: Exception) {
                    // ignore
                }
            }
            try {
                conn.close()
            } catch (_: Exception) {
                // ignore
            }
        }
        connection = null
        device = null
        usbInterface = null
        inEndpoint = null
        outEndpoint = null
    }
}
