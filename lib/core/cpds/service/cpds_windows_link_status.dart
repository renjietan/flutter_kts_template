import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class _AdapterAddresses extends Struct {
  @Uint32()
  external int length;

  @Uint32()
  external int ifIndex;

  external Pointer<_AdapterAddresses> next;

  external Pointer<Uint8> adapterName;

  external Pointer<_UnicastAddress> firstUnicastAddress;

  external Pointer<Uint8> firstAnycastAddress;

  external Pointer<Uint8> firstMulticastAddress;

  external Pointer<Uint8> firstDnsServerAddress;

  external Pointer<Uint16> dnsSuffix;

  external Pointer<Uint16> description;

  external Pointer<Uint16> friendlyName;

  @Array(8)
  external Array<Uint8> physicalAddress;

  @Uint32()
  external int physicalAddressLength;

  @Uint32()
  external int flags;

  @Uint32()
  external int mtu;

  @Uint32()
  external int ifType;

  @Uint32()
  external int operStatus;
}

final class _SocketAddress extends Struct {
  external Pointer<Uint8> lpSockaddr;

  @Int32()
  external int sockaddrLength;
}

final class _UnicastAddress extends Struct {
  @Uint32()
  external int length;

  @Uint32()
  external int flags;

  external Pointer<_UnicastAddress> next;

  external _SocketAddress address;

  @Uint32()
  external int prefixOrigin;

  @Uint32()
  external int suffixOrigin;

  @Uint32()
  external int dadState;

  @Uint32()
  external int validLifetime;

  @Uint32()
  external int preferredLifetime;

  @Uint32()
  external int leaseLifetime;

  @Uint8()
  external int onLinkPrefixLength;
}

typedef _GetAdaptersAddressesNative = Uint32 Function(
  Uint32 family,
  Uint32 flags,
  Pointer<Void> reserved,
  Pointer<_AdapterAddresses> adapterAddresses,
  Pointer<Uint32> sizePointer,
);
typedef _GetAdaptersAddressesDart = int Function(
  int family,
  int flags,
  Pointer<Void> reserved,
  Pointer<_AdapterAddresses> adapterAddresses,
  Pointer<Uint32> sizePointer,
);

/// Windows only: read interface link status via iphlpapi GetAdaptersAddresses.
class CpdsWindowsLinkStatus {
  CpdsWindowsLinkStatus._();

  static const int _afInet = 2;
  static const int _ifOperStatusUp = 1;

  static Map<String, bool> load() {
    final map = <String, bool>{};
    try {
      final lib = DynamicLibrary.open('iphlpapi.dll');
      final getAdapters = lib.lookupFunction<_GetAdaptersAddressesNative,
          _GetAdaptersAddressesDart>('GetAdaptersAddresses');

      final sizePtr = calloc<Uint32>(1);
      try {
        getAdapters(_afInet, 0, nullptr, nullptr, sizePtr);
        final size = sizePtr.value;
        if (size == 0) return map;

        final buffer = calloc<Uint8>(size);
        try {
          final adapterPtr = buffer.cast<_AdapterAddresses>();
          sizePtr.value = size;
          final ret = getAdapters(_afInet, 0, nullptr, adapterPtr, sizePtr);
          if (ret != 0) return map;

          var adapter = adapterPtr;
          while (adapter != nullptr) {
            final up = adapter.ref.operStatus == _ifOperStatusUp;
            var unicast = adapter.ref.firstUnicastAddress;
            while (unicast != nullptr) {
              final sockaddr = unicast.ref.address.lpSockaddr;
              final ip = '${(sockaddr + 4).value}.'
                  '${(sockaddr + 5).value}.'
                  '${(sockaddr + 6).value}.'
                  '${(sockaddr + 7).value}';
              map[ip] = up;
              unicast = unicast.ref.next;
            }
            adapter = adapter.ref.next;
          }
        } finally {
          calloc.free(buffer);
        }
      } finally {
        calloc.free(sizePtr);
      }
    } catch (_) {
      return const {};
    }
    return map;
  }
}
