// Model responsável por representar um relato dentro do aplicativo.
class Relato {
  final int? id;
  final String texto;
  final DateTime criadoEm;

  // Caminho da foto armazenada no dispositivo.
  final String? caminhoFoto;

  // Caminho do vídeo armazenado no dispositivo.
  final String? caminhoVideo;

  Relato({
    this.id,
    required this.texto,
    required this.criadoEm,
    this.caminhoFoto,
    this.caminhoVideo,
  });

  // Converte o objeto Relato para um Map.
  // Esse formato é utilizado pelo SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'texto': texto,
      'criado_em': criadoEm.toIso8601String(),
      'caminho_foto': caminhoFoto,
      'caminho_video': caminhoVideo,
    };
  }

  // Converte os dados do SQLite novamente em um objeto Relato.
  factory Relato.fromMap(Map<String, dynamic> map) {
    return Relato(
      id: map['id'] as int?,
      texto: map['texto'] as String,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      caminhoFoto: map['caminho_foto'] as String?,
      caminhoVideo: map['caminho_video'] as String?,
    );
  }
}