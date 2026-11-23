

class DevicesModel {
  dynamic id;
  String? title;
  List<dynamic>? items;

  DevicesModel({this.id, this.title, this.items});
  static List<DevicesModel> fromNewApiJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];

    final normalisedItems = rawItems.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      item['icon'] = {'path': item['path'] ?? ''};
      item['icon_color'] = _onlineToIconColor(item['online']?.toString() ?? '');
      item.putIfAbsent('tail', () => <dynamic>[]);
      item.putIfAbsent('stop_duration', () => '-');

      return item;
    }).toList();

    // Single pseudo-group — groupId is always 0
    return [
      DevicesModel(
        id:    0,
        title: 'All Vehicles',
        items: normalisedItems,
      ),
    ];
  }

  // Maps new API 'online' value → old API 'icon_color' value
  static String _onlineToIconColor(String online) {
    switch (online.toLowerCase()) {
      case 'online':  return 'green';
      case 'ack':     return 'red';
      case 'offline': return 'blue';
      case 'engine':  return 'yellow';
      default:        return 'blue';
    }
  }
}