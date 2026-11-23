import 'package:flutter/foundation.dart';

class DeviceHistoryModel {
  final List<HistoryItem> items;
  final dynamic distanceSum;
  final dynamic topSpeed;
  final dynamic moveDuration;
  final dynamic stopDuration;
  final List<ItemClass> itemClass;

  DeviceHistoryModel({
    required this.items,
    required this.distanceSum,
    required this.topSpeed,
    required this.moveDuration,
    required this.stopDuration,
    required this.itemClass,
  });

  factory DeviceHistoryModel.fromJson(Map<dynamic, dynamic> json) {
    try {
      return DeviceHistoryModel(
        items: List.from(json['items'] ?? [])
            .map((e) => HistoryItem.fromJson(e as Map<dynamic, dynamic>))
            .toList(),
        distanceSum: json['distance_sum'] ?? '0',
        topSpeed: json['top_speed'] ?? '0',
        moveDuration: json['move_duration'] ?? '-',
        stopDuration: json['stop_duration'] ?? '-',
        itemClass: List.from(json['item_class'] ?? [])
            .map((e) => ItemClass.fromJson(e as Map<dynamic, dynamic>))
            .toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing DeviceHistoryModel: $e');
      }
      rethrow;
    }
  }

  Map<dynamic, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'distance_sum': distanceSum,
    'top_speed': topSpeed,
    'move_duration': moveDuration,
    'stop_duration': stopDuration,
    'item_class': itemClass.map((e) => e.toJson()).toList(),
  };
}

class HistoryItem {
  final dynamic status;
  final dynamic time;
  final dynamic show;
  final dynamic topSpeed;
  final dynamic avgSpeed;
  final dynamic left;
  final dynamic rawTime;
  final dynamic distance;
  final dynamic driver;
  final List<dynamic> statusItems;

  HistoryItem({
    required this.status,
    required this.time,
    required this.show,
    required this.topSpeed,
    required this.avgSpeed,
    required this.left,
    required this.rawTime,
    required this.distance,
    required this.driver,
    required this.statusItems,
  });

  factory HistoryItem.fromJson(Map<dynamic, dynamic> json) {
    try {
      return HistoryItem(
        status: json['status'] ?? 0,
        time: json['time'] ?? '-',
        show: json['show'] ?? json['raw_time'] ?? '-',
        left: json['left'] ?? '-',
        topSpeed: json['top_speed'] ?? '0',
        avgSpeed: json['average_speed'] ?? '0',
        rawTime: json['raw_time'] ?? '-',
        distance: json['distance'] ?? '0',
        driver: json['driver'],
        statusItems: List<dynamic>.from(json['items'] ?? []),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing HistoryItem: $e');
      }
      rethrow;
    }
  }

  Map<dynamic, dynamic> toJson() => {
    'status': status,
    'time': time,
    'show': show,
    'left': left,
    'top_speed': topSpeed,
    'average_speed': avgSpeed,
    'raw_time': rawTime,
    'distance': distance,
    'driver': driver,
    'items': statusItems,
  };
}

class ItemClass {
  final dynamic id;
  final dynamic value;
  final dynamic title;

  ItemClass({
    required this.id,
    required this.value,
    required this.title,
  });

  factory ItemClass.fromJson(Map<dynamic, dynamic> json) {
    try {
      return ItemClass(
        id: json['id'] ?? 0,
        value: json['value'] ?? '-',
        title: json['title'] ?? '-',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing ItemClass: $e');
      }
      rethrow;
    }
  }

  Map<dynamic, dynamic> toJson() => {
    'id': id,
    'value': value,
    'title': title,
  };
}