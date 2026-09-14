/// Quita el formato Markdown y los enlaces para que la voz no lea símbolos
/// como "asterisco" ni direcciones web.
String speakableText(String text) {
  return text
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'),
        (match) => match[1]!,
      )
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'^\s*(?:[-•*]|\d+\.)\s+', multiLine: true), '')
      .replaceAll(RegExp(r'[*_`#>~]'), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();
}
