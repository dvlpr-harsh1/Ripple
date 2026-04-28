abstract class SearchEvent {}

class SearchRequested extends SearchEvent {
  final String query;

  SearchRequested({required this.query});
}
