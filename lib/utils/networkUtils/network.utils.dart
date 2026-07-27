import 'dart:io';

import 'package:flutter_kts_template/logger/logger.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'network.info.dart';

/// 网络工具类 - 跨平台获取局域网 IPv4 接口信息
class NetworkUtil {
  NetworkUtil._();

  /// 获取所有 IPv4 局域网（私有）地址及其子网掩码和广播地址。
  ///
  /// 优先使用 dart:io 的 [NetworkInterface.list]（支持桌面、iOS 和最新 Android），
  /// 如果失败（如老旧 Android 系统不支持），则回退到 [network_info_plus] 插件。
  ///
  /// 返回 [NetworkInterfaceInfo] 列表，仅包含 A/B/C 类私有地址（RFC 1918）。
  /// 如果获取失败，返回空列表。
  static Future<List<NetworkInterfaceInfo>> getIPv4LANInterfaces() async {
    try {
      // 优先使用 dart:io（覆盖桌面、iOS、Android 新版）
      return await _getInterfacesViaDartIO();
    } catch (e) {
      // 如果抛出异常（例如 Android 旧版本不支持），使用 network_info_plus 备选
      GlobalLogger.logError('dart:io 方式失败，回退到 network_info_plus: $e');
      return await _getInterfacesViaNetworkInfoPlus();
    }
  }

  /// 使用 dart:io 的 NetworkInterface.list 获取所有网卡信息
  static Future<List<NetworkInterfaceInfo>> _getInterfacesViaDartIO() async {
    final List<NetworkInterfaceInfo> result = [];
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
    );

    for (final interface in interfaces) {
      for (final adder in interface.addresses) {
        if (adder.type != InternetAddressType.IPv4) continue;
        if (!_isPrivateIPv4(adder)) continue;
        final (mask, broadcast) = _calculateMaskAndBroadcast(adder);
        result.add(
          NetworkInterfaceInfo(
            interfaceName: interface.name,
            ip: adder.address,
            mask: mask,
            broadcast: broadcast,
          ),
        );
      }
    }
    return result;
  }

  /// 使用 network_info_plus 插件获取当前 Wi-Fi 信息（Android 备选）
  static Future<List<NetworkInterfaceInfo>>
  _getInterfacesViaNetworkInfoPlus() async {
    final info = NetworkInfo();
    final List<NetworkInterfaceInfo> result = [];

    try {
      final String? ip = await info.getWifiIP();
      if (ip == null || ip.isEmpty) {
        GlobalLogger.logWarn('无法获取 Wi-Fi IP 地址');
        return result;
      }

      final addr = InternetAddress(ip);
      if (!_isPrivateIPv4(addr)) {
        GlobalLogger.logWarn('Wi-Fi IP 不是私有地址，忽略');
        return result;
      }

      // 尝试从插件获取掩码和广播（可能为 null）
      final String? mask = await info.getWifiSubmask();
      final String? broadcast = await info.getWifiBroadcast();

      if (mask != null && broadcast != null) {
        result.add(
          NetworkInterfaceInfo(
            interfaceName: 'wlan0 (Wi-Fi)',
            ip: ip,
            mask: mask,
            broadcast: broadcast,
          ),
        );
      } else {
        // 插件未返回掩码/广播时，回退到基于 IP 类别的计算
        final (calcMask, calcBroadcast) = _calculateMaskAndBroadcast(addr);
        result.add(
          NetworkInterfaceInfo(
            interfaceName: 'wlan0 (Wi-Fi, 计算值)',
            ip: ip,
            mask: calcMask,
            broadcast: calcBroadcast,
          ),
        );
      }
    } catch (e) {
      GlobalLogger.logError('使用 network_info_plus 获取信息失败: $e');
    }
    return result;
  }

  /// 判断是否为私有 IPv4 地址（RFC 1918）
  static bool _isPrivateIPv4(InternetAddress addr) {
    if (addr.type != InternetAddressType.IPv4) return false;
    final raw = addr.rawAddress;
    final first = raw[0];
    if (first == 10) return true; // 10.0.0.0/8
    if (first == 172 && raw[1] >= 16 && raw[1] <= 31) {
      return true; // 172.16.0.0/12
    }
    if (first == 192 && raw[1] == 168) return true; // 192.168.0.0/16
    return false;
  }

  /* 根据 IP 类别计算子网掩码和广播地址（不依赖 prefixLength）
    类别	地址范围	默认子网掩码	二进制特征	主要用途	私有地址段（RFC 1918）	网卡能否获得该 IP？	你的代码是否处理？
    A 类	1.0.0.0 ~ 126.255.255.255	255.0.0.0 (/8)	最高位为 0	超大规模网络（骨干网、国家级网络）	10.0.0.0/8（即 10.x.x.x）	✅ 能	✅ 会处理
    B 类	128.0.0.0 ~ 191.255.255.255	255.255.0.0 (/16)	最高两位为 10	中等规模网络（大型企业、校园网）	172.16.0.0/12（172.16.x.x ~ 172.31.x.x）	✅ 能	✅ 会处理
    C 类	192.0.0.0 ~ 223.255.255.255	255.255.255.0 (/24)	最高三位为 110	小型网络（家庭/办公室路由器）	192.168.0.0/16（即 192.168.x.x）	✅ 能	✅ 会处理
    D 类	224.0.0.0 ~ 239.255.255.255	无（不是给主机用的）	最高四位为 1110	组播（Multicast）：视频会议、路由协议（OSPF、RIP）	无	❌ 不能（组播组标识，非主机地址）	❌ 不会处理（因为网卡不会获得）
    E 类	240.0.0.0 ~ 255.255.255.255	无（不是给主机用的）	最高四位为 1111	保留/实验：未大规模使用，255.255.255.255 为受限广播地址	无	❌ 不能（实验用途，非主机地址
  */
  static (String mask, String broadcast) _calculateMaskAndBroadcast(
    InternetAddress adder,
  ) {
    final ip = adder.rawAddress;
    final first = ip[0];

    List<int> mask;
    if (first == 10) {
      mask = [255, 0, 0, 0]; // A类 /8
    } else if (first == 172 && ip[1] >= 16 && ip[1] <= 31) {
      mask = [255, 255, 0, 0]; // B类 /16
    } else if (first == 192 && ip[1] == 168) {
      mask = [255, 255, 255, 0]; // C类 /24
    } else if (first == 169 && ip[1] == 254) {
      mask = [255, 255, 0, 0]; // 链路本地 /16
    } else {
      mask = [255, 255, 255, 0]; // 默认 /24
    }

    final List<String> broadcastParts = [];
    for (int i = 0; i < 4; i++) {
      broadcastParts.add('${ip[i] | (~mask[i] & 0xFF)}');
    }
    final broadcast = broadcastParts.join('.');
    final maskStr = mask.join('.');
    return (maskStr, broadcast);
  }
}
