String getDurationText(int durationInSeconds) {
  final String minutes = _formatNumber(durationInSeconds ~/ 60);
  final String seconds = _formatNumber(durationInSeconds % 60);

  return '$minutes : $seconds';
}

String _formatNumber(int number) {
  String numberStr = number.toString();
  if (number < 10) {
    numberStr = '0$numberStr';
  }

  return numberStr;
}