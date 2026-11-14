import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'database/database_helper.dart';
import 'models/relato.dart';

void main() {
  runApp(const MeusLembretesApp());
}

class MeusLembretesApp extends StatelessWidget {
  const MeusLembretesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meus Lembretes',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();

  final ImagePicker _picker = ImagePicker();

XFile? _fotoSelecionada;
XFile? _videoSelecionado;

  // Lista que vai armazenar os relatos vindos do banco.
  List<Relato> _relatos = [];

  Future<void> _selecionarFoto() async {
  final XFile? foto = await _picker.pickImage(
    source: ImageSource.gallery,
  );

  // Se o usuário cancelar a seleção, não faz nada.
  if (foto == null) {
    return;
  }

  // Guarda a foto selecionada na variável.
  setState(() {
    _fotoSelecionada = foto;
  });
}
// Abre a galeria do celular para selecionar um vídeo.
Future<void> _selecionarVideo() async {
  final XFile? video = await _picker.pickVideo(
    source: ImageSource.gallery,
  );

  // Se o usuário cancelar a seleção, não faz nada.
  if (video == null) {
    return;
  }

  // Guarda o vídeo selecionado na variável.
  setState(() {
    _videoSelecionado = video;
  });
}

  @override
  void initState() {
    super.initState();

    // Quando a tela abrir, busca os relatos salvos.
    _carregarRelatos();
  }
  Future<void> _editarRelato(Relato relato) async {
  final controllerEdicao = TextEditingController(
    text: relato.texto,
  );

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Editar relato'),
        content: TextField(
          controller: controllerEdicao,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Relato',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoTexto = controllerEdicao.text.trim();

              if (novoTexto.isEmpty) {
                return;
              }

              final relatoAtualizado = Relato(
                id: relato.id,
                texto: novoTexto,
                criadoEm: relato.criadoEm,
                caminhoFoto: relato.caminhoFoto,
                caminhoVideo: relato.caminhoVideo,
              );

              await DatabaseHelper.instance
                  .atualizarRelato(relatoAtualizado);

              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);

              await _carregarRelatos();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Relato atualizado com sucesso!',
                  ),
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );

  controllerEdicao.dispose();
}
 Future<void> _excluirRelato(Relato relato) async {
  if (relato.id == null) return;

  await DatabaseHelper.instance.excluirRelato(relato.id!);

  await _carregarRelatos();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Relato excluído com sucesso!'),
    ),
  );
}

  // Busca os relatos no SQLite.
  Future<void> _carregarRelatos() async {
    final relatos = await DatabaseHelper.instance.buscarRelatos();

    if (!mounted) return;

    setState(() {
      _relatos = relatos;
    });
  }
  // Copia uma foto ou vídeo para o armazenamento interno do aplicativo.
Future<String> _salvarArquivoLocal(
  XFile arquivo,
  String tipo,
) async {
  // Obtém a pasta interna do aplicativo.
  final diretorio = await getApplicationDocumentsDirectory();

  // Cria uma pasta exclusiva para as mídias dos relatos.
  final pastaMidias = Directory(
    '${diretorio.path}/midias',
  );

  // Se a pasta ainda não existir, ela será criada.
  if (!await pastaMidias.exists()) {
    await pastaMidias.create(
      recursive: true,
    );
  }

  // Obtém a extensão original do arquivo.
  final extensao = arquivo.path.contains('.')
      ? arquivo.path.substring(
          arquivo.path.lastIndexOf('.'),
        )
      : '';

  // Cria um nome único para evitar arquivos com nomes repetidos.
  final nomeArquivo =
      '${tipo}_${DateTime.now().microsecondsSinceEpoch}$extensao';

  final novoCaminho =
      '${pastaMidias.path}/$nomeArquivo';

  // Copia o arquivo selecionado para a pasta interna.
  await File(arquivo.path).copy(
    novoCaminho,
  );

  // Retorna o caminho definitivo.
  return novoCaminho;
}
  // Salva um novo relato.
Future<void> _salvarRelato() async {
  final texto = _controller.text.trim();

  // O relato precisa ter pelo menos texto, foto ou vídeo.
  if (texto.isEmpty &&
      _fotoSelecionada == null &&
      _videoSelecionado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Digite um relato ou adicione uma foto/vídeo.',
        ),
      ),
    );
    return;
  }

  String? caminhoFoto;
  String? caminhoVideo;

  // Se uma foto foi selecionada, salva uma cópia
  // no armazenamento interno do aplicativo.
  if (_fotoSelecionada != null) {
    caminhoFoto = await _salvarArquivoLocal(
      _fotoSelecionada!,
      'foto',
    );
  }

  // Se um vídeo foi selecionado, salva uma cópia
  // no armazenamento interno do aplicativo.
  if (_videoSelecionado != null) {
    caminhoVideo = await _salvarArquivoLocal(
      _videoSelecionado!,
      'video',
    );
  }

  // Cria o relato com texto, data e caminhos das mídias.
  final relato = Relato(
    texto: texto,
    criadoEm: DateTime.now(),
    caminhoFoto: caminhoFoto,
    caminhoVideo: caminhoVideo,
  );

  // Salva o relato no SQLite.
  await DatabaseHelper.instance.inserirRelato(relato);

  // Limpa o formulário depois de salvar.
  _controller.clear();

  if (!mounted) return;

  setState(() {
    _fotoSelecionada = null;
    _videoSelecionado = null;
  });

  // Atualiza a lista de relatos.
  await _carregarRelatos();

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Relato salvo com sucesso!',
      ),
    ),
  );
}
  // Formata a data e horário para exibição.
  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;

    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano • $hora:$minuto';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Meus Lembretes'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo para escrever o relato.
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Novo relato',
              hintText: 'Digite aqui...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 12),

// Botões para adicionar foto ou vídeo.
Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: _selecionarFoto,
        icon: const Icon(Icons.photo),
        label: const Text('Foto'),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: OutlinedButton.icon(
        onPressed: _selecionarVideo,
        icon: const Icon(Icons.videocam),
        label: const Text('Vídeo'),
      ),
    ),
  ],
),

// Mostra uma prévia da foto selecionada.
if (_fotoSelecionada != null) ...[
  ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(_fotoSelecionada!.path),
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),

  const SizedBox(height: 12),
],

// Mostra que um vídeo foi selecionado.
if (_videoSelecionado != null) ...[
  const Row(
    children: [
      Icon(Icons.check_circle),
      SizedBox(width: 8),
      Text('Vídeo selecionado'),
    ],
  ),

  const SizedBox(height: 12),
],

const SizedBox(height: 12),

          // Botão salvar.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvarRelato,
              child: const Text('Salvar'),
            ),
          ),

          const SizedBox(height: 20),

          // Lista dos relatos cadastrados.
          Expanded(
            child: _relatos.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum relato registrado.',
                    ),
                  )
                : ListView.builder(
                    itemCount: _relatos.length,
                    itemBuilder: (context, index) {
                      final relato = _relatos[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                         onTap: () {
                      _editarRelato(relato);
                    },
                        title: Text(
                         relato.texto,
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                         ),
                          subtitle: Text(
                          _formatarData(relato.criadoEm),
                         ),
                            trailing: IconButton(
                             icon: const Icon(Icons.delete),
                              onPressed: () {
                             _excluirRelato(relato);
                          },
                        ),
                      ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
}