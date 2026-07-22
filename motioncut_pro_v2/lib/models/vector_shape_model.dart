import 'package:equatable/equatable.dart';

enum VectorShapeType {
  rectangle,
  roundedRectangle,
  circle,
  ellipse,
  line,
  polygon,
  star,
  path,
  arrow,
  heart,
}

enum VectorFillType {
  solid,
  gradientLinear,
  gradientRadial,
  none,
}

enum VectorStrokeCap {
  butt,
  round,
  square,
}

class VectorShapeModel extends Equatable {
  final String id;
  final VectorShapeType shapeType;
  final VectorFillType fillType;
  final int fillColor;
  final int? fillColor2;
  final double fillOpacity;
  final bool hasStroke;
  final int strokeColor;
  final double strokeWidth;
  final VectorStrokeCap strokeCap;
  final List<PointModel> points;
  final double rotation;
  final double scale;
  final PointModel position;
  final double cornerRadius;
  final int sides;
  final double innerRadius;
  final bool closed;

  const VectorShapeModel({
    required this.id,
    required this.shapeType,
    this.fillType = VectorFillType.solid,
    this.fillColor = 0xFFFFFFFF,
    this.fillColor2,
    this.fillOpacity = 1.0,
    this.hasStroke = false,
    this.strokeColor = 0xFF000000,
    this.strokeWidth = 1.0,
    this.strokeCap = VectorStrokeCap.round,
    this.points = const [],
    this.rotation = 0.0,
    this.scale = 1.0,
    this.position = const PointModel(0, 0),
    this.cornerRadius = 0.0,
    this.sides = 5,
    this.innerRadius = 0.5,
    this.closed = true,
  });

  VectorShapeModel copyWith({
    VectorShapeType? shapeType,
    VectorFillType? fillType,
    int? fillColor,
    int? fillColor2,
    double? fillOpacity,
    bool? hasStroke,
    int? strokeColor,
    double? strokeWidth,
    VectorStrokeCap? strokeCap,
    List<PointModel>? points,
    double? rotation,
    double? scale,
    PointModel? position,
    double? cornerRadius,
    int? sides,
    double? innerRadius,
    bool? closed,
  }) =>
      VectorShapeModel(
        id: id,
        shapeType: shapeType ?? this.shapeType,
        fillType: fillType ?? this.fillType,
        fillColor: fillColor ?? this.fillColor,
        fillColor2: fillColor2 ?? this.fillColor2,
        fillOpacity: fillOpacity ?? this.fillOpacity,
        hasStroke: hasStroke ?? this.hasStroke,
        strokeColor: strokeColor ?? this.strokeColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        strokeCap: strokeCap ?? this.strokeCap,
        points: points ?? this.points,
        rotation: rotation ?? this.rotation,
        scale: scale ?? this.scale,
        position: position ?? this.position,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        sides: sides ?? this.sides,
        innerRadius: innerRadius ?? this.innerRadius,
        closed: closed ?? this.closed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'shapeType': shapeType.name,
        'fillType': fillType.name,
        'fillColor': fillColor,
        'fillColor2': fillColor2,
        'fillOpacity': fillOpacity,
        'hasStroke': hasStroke,
        'strokeColor': strokeColor,
        'strokeWidth': strokeWidth,
        'strokeCap': strokeCap.name,
        'points': points.map((p) => p.toJson()).toList(),
        'rotation': rotation,
        'scale': scale,
        'position': position.toJson(),
        'cornerRadius': cornerRadius,
        'sides': sides,
        'innerRadius': innerRadius,
        'closed': closed,
      };

  factory VectorShapeModel.fromJson(Map<String, dynamic> json) => VectorShapeModel(
        id: json['id'] as String,
        shapeType: VectorShapeType.values.byName(json['shapeType'] as String? ?? 'rectangle'),
        fillType: VectorFillType.values.byName(json['fillType'] as String? ?? 'solid'),
        fillColor: (json['fillColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        fillColor2: (json['fillColor2'] as num?)?.toInt(),
        fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 1.0,
        hasStroke: json['hasStroke'] as bool? ?? false,
        strokeColor: (json['strokeColor'] as num?)?.toInt() ?? 0xFF000000,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 1.0,
        strokeCap: VectorStrokeCap.values.byName(json['strokeCap'] as String? ?? 'round'),
        points: (json['points'] as List<dynamic>?)
                ?.map((p) => PointModel.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        position: json['position'] != null
            ? PointModel.fromJson(json['position'] as Map<String, dynamic>)
            : const PointModel(0, 0),
        cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 0.0,
        sides: (json['sides'] as num?)?.toInt() ?? 5,
        innerRadius: (json['innerRadius'] as num?)?.toDouble() ?? 0.5,
        closed: json['closed'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        id, shapeType, fillType, fillColor, fillColor2, fillOpacity,
        hasStroke, strokeColor, strokeWidth, strokeCap, points,
        rotation, scale, position, cornerRadius, sides, innerRadius, closed
      ];
}

class PointModel extends Equatable {
  final double x;
  final double y;
  const PointModel(this.x, this.y);

  PointModel copyWith({double? x, double? y}) => PointModel(x ?? this.x, y ?? this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory PointModel.fromJson(Map<String, dynamic> json) =>
      PointModel((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

  @override
  List<Object?> get props => [x, y];
}
