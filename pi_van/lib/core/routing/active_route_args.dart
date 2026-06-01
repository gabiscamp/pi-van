import '../../domain/entities/route_stop_entity.dart';
import '../../domain/enums/route_type.dart';

/// Argumentos passados da tela de montagem para a tela de navegação ativa.
class ActiveRouteArgs {
  final RouteType type;
  final List<RouteStopEntity> stops;

  const ActiveRouteArgs({required this.type, required this.stops});
}
