import 'dart:io';

import 'cpds_windows_link_status.dart';

import '../cpds_exception.dart';
import '../model/cpds_enums.dart';
import '../model/cpds_models.dart';

class CpdsNetworkInterfaceService {
  CpdsNetworkInterfaceService._();

  static Future<List<CpdsNetworkInterface>> listInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      final windowsLinkMap = Platform.isWindows
          ? await _windowsLinkStatusMap()
          : const <String, bool>{};
      final result = <CpdsNetworkInterface>[];
      for (final item in interfaces) {
        if (_isExcludedName(item.name)) continue;
        final ipv4 = _firstUsableIpv4(item);
        if (ipv4 == null) continue;
        final wired = !_isWirelessName(item.name);
        final linkUp = Platform.isWindows
            ? (windowsLinkMap[ipv4] ?? true)
            : Platform.isAndroid || Platform.isLinux
            ? _linuxLinkUp(item.name)
            : true;
        result.add(
          CpdsNetworkInterface(
            name: item.name,
            index: item.index,
            ipv4: ipv4,
            linkUp: linkUp,
            wired: wired,
          ),
        );
      }
      result.sort((a, b) {
        if (a.wired != b.wired) return a.wired ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      if (result.isEmpty) {
        throw CpdsException(
          CpdsErrorCode.networkInterfaceError,
          params: {'count': 0},
          message: 'no network interface',
        );
      }
      return result;
    } on CpdsException {
      rethrow;
    } catch (error) {
      throw CpdsException(
        CpdsErrorCode.networkInterfaceError,
        params: {'cause': error.toString()},
        message: 'unable to enumerate network interfaces',
      );
    }
  }

  static bool _linuxLinkUp(String name) {
    try {
      final carrier = File('/sys/class/net/$name/carrier');
      if (carrier.existsSync()) {
        return carrier.readAsStringSync().trim() == '1';
      }
      final operstate = File('/sys/class/net/$name/operstate');
      if (operstate.existsSync()) {
        return operstate.readAsStringSync().trim() == 'up';
      }
    } catch (_) {}
    return true;
  }

  static Future<Map<String, bool>> _windowsLinkStatusMap() async {
    return CpdsWindowsLinkStatus.load();
  }

  static bool _isWirelessName(String name) {
    final lower = name.toLowerCase();
    const wireless = ['wi-fi', 'wifi', 'wlan', 'wireless', '无线'];
    return wireless.any(lower.contains);
  }

  static bool _isExcludedName(String name) {
    final lower = name.toLowerCase();
    const excluded = [
      'vpn',
      'virtual',
      'vethernet',
      'hyper-v',
      'bluetooth',
      'docker',
      'veth',
      'virbr',
      'vmware',
      'tap',
      'tun',
    ];
    return excluded.any(lower.contains);
  }

  static String? _firstUsableIpv4(NetworkInterface item) {
    for (final address in item.addresses) {
      if (address.type != InternetAddressType.IPv4) continue;
      if (address.isLoopback || address.isLinkLocal) continue;
      final raw = address.rawAddress;
      if (raw.length != 4) continue;
      if (_isPrivate(raw)) return address.address;
    }
    return null;
  }

  static bool _isPrivate(List<int> raw) {
    final first = raw[0];
    if (first == 10) return true;
    if (first == 172 && raw[1] >= 16 && raw[1] <= 31) return true;
    if (first == 192 && raw[1] == 168) return true;
    return false;
  }
}
