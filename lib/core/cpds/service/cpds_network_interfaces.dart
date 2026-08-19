import 'dart:io';

import '../cpds_exception.dart';
import '../model/cpds_enums.dart';
import '../model/cpds_models.dart';

class CpdsNetworkInterfaceService {
  CpdsNetworkInterfaceService._();

  static Future<List<CpdsNetworkInterface>> listWiredInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      final result = <CpdsNetworkInterface>[];
      for (final item in interfaces) {
        if (!_eligibleName(item.name)) continue;
        final ipv4 = _firstUsableIpv4(item);
        if (ipv4 == null) continue;
        result.add(
          CpdsNetworkInterface(name: item.name, index: item.index, ipv4: ipv4),
        );
      }
      result.sort((a, b) => a.name.compareTo(b.name));
      if (result.isEmpty) {
        throw CpdsException(
          CpdsErrorCode.networkInterfaceError,
          params: {'count': 0},
          message: 'no wired interface',
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

  static bool _eligibleName(String name) {
    final lower = name.toLowerCase();
    const excluded = [
      'wi-fi',
      'wifi',
      'wlan',
      'wireless',
      '无线',
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
    return !excluded.any(lower.contains);
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
