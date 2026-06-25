class DeviceConfigServerTopology {
  String? dhcp;
  String? ipv4Subnet;
  String? netmask;
  String? networkSegment;

  DeviceConfigServerTopology({
    this.dhcp,
    this.ipv4Subnet,
    this.netmask,
    this.networkSegment,
  });

  DeviceConfigServerTopology.fromJson(Map<String, dynamic> json) {
    dhcp = json['Dhcp'];
    ipv4Subnet = json['Ipv4Subnet'];
    netmask = json['Netmask'];
    networkSegment = json['NetworkSegment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Dhcp'] = dhcp;
    data['Ipv4Subnet'] = ipv4Subnet;
    data['Netmask'] = netmask;
    data['NetworkSegment'] = networkSegment;
    return data;
  }
}
