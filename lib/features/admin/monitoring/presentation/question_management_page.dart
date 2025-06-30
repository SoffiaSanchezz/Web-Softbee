import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import 'package:sotfbee/features/admin/monitoring/widgets/enhanced_card_widget.dart';
import '../models/enhanced_models.dart';

class QuestionsManagementScreen extends StatefulWidget {
  const QuestionsManagementScreen({Key? key}) : super(key: key);

  @override
  _QuestionsManagementScreenState createState() =>
      _QuestionsManagementScreenState();
}

class _QuestionsManagementScreenState extends State<QuestionsManagementScreen> {
  // Controladores
  final TextEditingController _preguntaController = TextEditingController();
  final TextEditingController _opcionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _bankSearchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Estado
  List<Pregunta> preguntas = [];
  List<Pregunta> filteredPreguntas = [];
  List<Apiario> apiarios = [];
  List<PreguntaTemplate> questionBankTemplates = [];
  bool isLoading = true;
  bool isConnected = false;
  bool isBankLoading = false;

  // Estado del formulario
  String tipoRespuestaSeleccionado = "texto";
  List<Opcion> opcionesTemporales = [];
  int? selectedApiarioId;
  bool obligatoriaSeleccionada = false;

  // UI Estado
  String? selectedCategoria;
  bool showQuestionBank = false;

  // Colores actualizados - eliminando azules
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorVerde = const Color(0xFF4CAF50);
  final Color colorAmarilloOscuro = const Color(0xFFF57C00); // Reemplaza azul
  final Color colorMorado = const Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _loadData();
      await _checkConnection();
      await _loadQuestionBank();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error al inicializar: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadQuestionBank() async {
    setState(() => isBankLoading = true);
    try {
      final templates = await EnhancedApiService.obtenerPlantillasPreguntas();
      setState(() => questionBankTemplates = templates);
    } catch (e) {
      _showSnackBar('Error al cargar banco de preguntas: $e', Colors.red);
    } finally {
      setState(() => isBankLoading = false);
    }
  }

  Future<void> _loadData() async {
    try {
      apiarios = await EnhancedApiService.obtenerApiarios();
      if (selectedApiarioId != null) {
        preguntas = await EnhancedApiService.obtenerPreguntasApiario(
          selectedApiarioId!,
          soloActivas: false,
        );
      } else {
        preguntas = [];
      }
      _filterPreguntas();
      _validateKeys();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
    }
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await EnhancedApiService.verificarConexion();
      setState(() {
        isConnected = connected;
      });
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  void _filterPreguntas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPreguntas = List.from(preguntas);
      } else {
        filteredPreguntas = preguntas.where((pregunta) {
          return pregunta.texto.toLowerCase().contains(query);
        }).toList();
      }
      filteredPreguntas.sort((a, b) => a.orden.compareTo(b.orden));
    });
  }

  void _validateKeys() {
    debugPrint('🔍 Validando keys de ${filteredPreguntas.length} preguntas:');
    Set<String> keys = {};
    bool hasError = false;
    for (int i = 0; i < filteredPreguntas.length; i++) {
      final pregunta = filteredPreguntas[i];
      final key = 'pregunta_${pregunta.id}';
      if (keys.contains(key)) {
        debugPrint('❌ KEY DUPLICADA: $key en índice $i');
        hasError = true;
      } else {
        keys.add(key);
        debugPrint(
          '✅ Key válida: $key (ID: ${pregunta.id}, Orden: ${pregunta.orden})',
        );
      }
    }
    if (!hasError) {
      debugPrint('✅ Todas las keys son únicas');
    }
  }

  void _reorderPreguntas(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Pregunta movedItem = filteredPreguntas.removeAt(oldIndex);
      filteredPreguntas.insert(newIndex, movedItem);
      List<Pregunta> tempAllQuestions = [];
      Set<String> filteredKeys = filteredPreguntas
          .map((p) => p.flutterKey)
          .toSet();
      tempAllQuestions.addAll(filteredPreguntas);
      for (var q in preguntas) {
        if (!filteredKeys.contains(q.flutterKey)) {
          tempAllQuestions.add(q);
        }
      }
      for (int i = 0; i < tempAllQuestions.length; i++) {
        tempAllQuestions[i] = tempAllQuestions[i].copyWith(orden: i + 1);
      }
      preguntas = tempAllQuestions;
      _filterPreguntas();
    });
    _saveOrder();
  }

  Future<void> _saveOrder() async {
    try {
      if (selectedApiarioId != null) {
        final orden = preguntas.map((p) => p.id.toString()).toList();
        await EnhancedApiService.reordenarPreguntas(selectedApiarioId!, orden);
        _showSnackBar('Orden actualizado correctamente', colorVerde);
      }
    } catch (e) {
      debugPrint("❌ Error al guardar orden: $e");
      _showSnackBar('Error al guardar orden: $e', Colors.red);
      await _loadData();
    }
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = _lerpDouble(1, 6, animValue);
        final double scale = _lerpDouble(1, 1.02, animValue);
        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: elevation,
            borderRadius: BorderRadius.circular(12),
            shadowColor: colorNaranja.withOpacity(0.3),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: AppBar(
        title: Text('Gestión de Preguntas'),
        actions: [IconButton(icon: Icon(Icons.sync), onPressed: _syncData)],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(isTablet),
      floatingActionButton: selectedApiarioId != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "bank",
                  onPressed: _showQuestionBankDialog,
                  backgroundColor: colorAmarilloOscuro, // Cambiado de azul
                  child: Icon(Icons.library_books, color: Colors.white),
                ).animate().scale(delay: 600.ms),
                SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: "new",
                  onPressed: _showPreguntaDialog,
                  backgroundColor: colorVerde,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Nueva Pregunta',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().scale(delay: 800.ms),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(bool isTablet) {
    return Column(
      children: [
        _buildHeader(isTablet),
        Expanded(
          child: selectedApiarioId == null
              ? _buildSelectApiarioPrompt()
              : _buildPreguntasList(isTablet),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          EnhancedCardWidget(
            title: 'Seleccionar Apiario',
            icon: Icons.location_on,
            color: colorNaranja,
            isCompact: true,
            animationDelay: 0,
            trailing: Container(
              width: 200,
              child: DropdownButtonFormField<int>(
                value: selectedApiarioId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: 'Selecciona...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                ),
                items: apiarios.map((apiario) {
                  return DropdownMenuItem<int>(
                    value: apiario.id,
                    child: Text(
                      apiario.nombre,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedApiarioId = value;
                  });
                  if (value != null) {
                    EnhancedApiService.loadDefaultQuestions(value);
                  }
                  _loadData();
                },
              ),
            ),
          ),
          if (selectedApiarioId != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Total',
                    value: preguntas.length.toString(),
                    icon: Icons.quiz,
                    color: colorVerde,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Activas',
                    value: preguntas.where((p) => p.activa).length.toString(),
                    icon: Icons.check_circle,
                    color: colorAmarillo,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Opciones',
                    value: preguntas
                        .where(
                          (p) => p.opciones != null && p.opciones!.isNotEmpty,
                        )
                        .length
                        .toString(),
                    icon: Icons.list,
                    color: colorNaranja,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Banco',
                    value: questionBankTemplates.length.toString(),
                    icon: Icons.library_books,
                    color: colorAmarilloOscuro, // Cambiado de azul
                    onTap: _showQuestionBankDialog,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar preguntas...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  prefixIcon: Icon(Icons.search, color: colorNaranja, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterPreguntas();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  _filterPreguntas();
                  setState(() {});
                },
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectApiarioPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 64, color: colorNaranja),
          SizedBox(height: 16),
          Text(
            'Selecciona un Apiario',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Primero selecciona un apiario para gestionar\nsus preguntas de monitoreo',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasList(bool isTablet) {
    if (filteredPreguntas.isEmpty) {
      return _buildEmptyState();
    }

    Map<String, List<Pregunta>> groupedPreguntas = {};
    for (var pregunta in filteredPreguntas) {
      final category = pregunta.categoria ?? 'Sin Categoría';
      if (groupedPreguntas[category] == null) {
        groupedPreguntas[category] = [];
      }
      groupedPreguntas[category]!.add(pregunta);
    }

    final sortedCategories = groupedPreguntas.keys.toList()..sort();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final category = sortedCategories[index];
          final preguntasInCategory = groupedPreguntas[category]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorNaranja,
                  ),
                ),
              ),
              ReorderableListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  // Find the actual indices in the main list
                  final oldItem = preguntasInCategory[oldIndex];
                  final oldListIndex = preguntas.indexWhere(
                    (p) => p.id == oldItem.id,
                  );
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final newItem = preguntasInCategory[newIndex];
                  final newListIndex = preguntas.indexWhere(
                    (p) => p.id == newItem.id,
                  );
                  _reorderPreguntas(oldListIndex, newListIndex);
                },
                proxyDecorator: _proxyDecorator,
                children: preguntasInCategory.map((pregunta) {
                  return Container(
                    key: ValueKey('pregunta_${pregunta.id}'),
                    margin: EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              pregunta.activa
                                  ? Colors.white
                                  : Colors.grey[100]!,
                              pregunta.activa
                                  ? colorAmbarClaro.withOpacity(0.2)
                                  : Colors.grey[200]!,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorNaranja.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorNaranja.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.drag_handle,
                                    color: colorNaranja,
                                    size: 18,
                                  ),
                                  SizedBox(height: 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorNaranja,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${pregunta.orden}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pregunta.texto,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: pregunta.activa
                                          ? Colors.black87
                                          : Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _buildInfoChip(
                                        _getTypeLabel(pregunta.tipoRespuesta),
                                        _getTypeColor(pregunta.tipoRespuesta),
                                      ),
                                      if (pregunta.obligatoria)
                                        _buildInfoChip(
                                          'Obligatoria',
                                          Colors.red,
                                        ),
                                      if (pregunta.opciones != null &&
                                          pregunta.opciones!.isNotEmpty)
                                        _buildInfoChip(
                                          '${pregunta.opciones!.length} opciones',
                                          colorVerde,
                                        ),
                                    ],
                                  ),
                                  if (pregunta.opciones != null &&
                                      pregunta.opciones!.isNotEmpty) ...[
                                    SizedBox(height: 6),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorVerde.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: colorVerde.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Opciones:',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: colorVerde,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: pregunta.opciones!
                                                .take(4)
                                                .map((opcion) {
                                                  return Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: colorVerde
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      opcion.valor,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 9,
                                                            color: colorVerde,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                          ),
                                          if (pregunta.opciones!.length > 4)
                                            Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Text(
                                                '+${pregunta.opciones!.length - 4} más',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  color: colorVerde.withOpacity(
                                                    0.7,
                                                  ),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Switch(
                                  value: pregunta.activa,
                                  onChanged: (value) =>
                                      _togglePreguntaActiva(pregunta, value),
                                  activeColor: colorVerde,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: colorNaranja,
                                  ),
                                  onSelected: (value) =>
                                      _handleMenuAction(value, pregunta),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: _buildMenuItem(
                                        Icons.edit,
                                        'Editar',
                                        colorNaranja,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'duplicate',
                                      child: _buildMenuItem(
                                        Icons.copy,
                                        'Duplicar',
                                        colorAmarillo,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: _buildMenuItem(
                                        Icons.delete,
                                        'Eliminar',
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty
                ? Icons.search_off
                : Icons.quiz_outlined,
            size: 64,
            color: colorNaranja,
          ),
          SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron preguntas'
                : 'No hay preguntas configuradas',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Agrega tu primera pregunta para comenzar\no explora el banco de preguntas',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: _showQuestionBankDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorNaranja,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Explorar Banco de Preguntas',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 8),
        Text(text, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Color _getTypeColor(String? tipo) {
    switch (tipo) {
      case 'opciones':
        return colorVerde;
      case 'numero':
        return colorNaranja;
      case 'rango':
        return colorMorado;
      default:
        return colorAmarillo;
    }
  }

  String _getTypeLabel(String? tipo) {
    switch (tipo) {
      case 'opciones':
        return 'Opciones';
      case 'numero':
        return 'Número';
      case 'rango':
        return 'Rango';
      default:
        return 'Texto';
    }
  }

  void _handleMenuAction(String action, Pregunta pregunta) {
    switch (action) {
      case 'edit':
        _showPreguntaDialog(pregunta: pregunta);
        break;
      case 'duplicate':
        _duplicatePregunta(pregunta);
        break;
      case 'delete':
        _confirmDeletePregunta(pregunta);
        break;
    }
  }

  Future<void> _togglePreguntaActiva(Pregunta pregunta, bool activa) async {
    try {
      final updatedPregunta = pregunta.copyWith(activa: activa);
      await EnhancedApiService.actualizarPregunta(
        pregunta.id,
        updatedPregunta.toJson(),
      );
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al actualizar estado: $e', Colors.red);
    }
  }

  void _showQuestionBankDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorAmarilloOscuro, colorNaranja],
                    ), // Cambiado de azul-morado
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.library_books, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Banco de Preguntas',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${questionBankTemplates.length} preguntas predefinidas',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _bankSearchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar en el banco de preguntas...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorAmarilloOscuro,
                          ), // Cambiado de azul
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) => setDialogState(() {}),
                      ),
                      SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip(
                              'Todas',
                              null,
                              selectedCategoria,
                              setDialogState,
                            ),
                            ..._categorias.map(
                              (categoria) => _buildCategoryChip(
                                categoria,
                                categoria,
                                selectedCategoria,
                                setDialogState,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildQuestionBankList(setDialogState)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _categorias =>
      questionBankTemplates.map((t) => t.categoria).toSet().toList()..sort();

  Widget _buildCategoryChip(
    String label,
    String? value,
    String? selected,
    StateSetter setDialogState,
  ) {
    final isSelected = selected == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : colorAmarilloOscuro, // Cambiado de azul
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setDialogState(() {
            selectedCategoria = selected ? value : null;
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: colorAmarilloOscuro, // Cambiado de azul
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildQuestionBankList(StateSetter setDialogState) {
    List<PreguntaTemplate> filteredTemplates = questionBankTemplates;
    if (selectedCategoria != null) {
      filteredTemplates = filteredTemplates
          .where((t) => t.categoria == selectedCategoria)
          .toList();
    }

    final searchQuery = _bankSearchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredTemplates = filteredTemplates
          .where(
            (t) =>
                t.texto.toLowerCase().contains(searchQuery) ||
                t.categoria.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    if (filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No se encontraron preguntas',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildQuestionBankItem(template, setDialogState);
      },
    );
  }

  Widget _buildQuestionBankItem(
    PreguntaTemplate template,
    StateSetter setDialogState,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _addQuestionFromTemplate(template),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        template.categoria,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getCategoryColor(
                          template.categoria,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      template.categoria,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(template.categoria),
                      ),
                    ),
                  ),
                  Spacer(),
                  _buildInfoChip(
                    _getTypeLabel(template.tipoRespuesta),
                    _getTypeColor(template.tipoRespuesta),
                  ),
                  if (template.obligatoria) ...[
                    SizedBox(width: 4),
                    _buildInfoChip('Obligatoria', Colors.red),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Text(
                template.texto,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (template.opciones != null &&
                  template.opciones!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorVerde.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorVerde.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opciones predefinidas:',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorVerde,
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: template.opciones!.take(5).map((opcion) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colorVerde.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              opcion,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: colorVerde,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (template.opciones!.length > 5)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '+${template.opciones!.length - 5} opciones más',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: colorVerde.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (template.min != null && template.max != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorNaranja.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Rango: ${template.min} - ${template.max}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colorNaranja,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _addQuestionFromTemplate(template),
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: colorAmarilloOscuro, // Cambiado de azul
                    ),
                    label: Text(
                      'Agregar Pregunta',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorAmarilloOscuro, // Cambiado de azul
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria) {
      case 'Estado de la Colmena':
        return colorVerde;
      case 'Producción':
        return colorAmarillo;
      case 'Salud':
        return Colors.red;
      case 'Alimentación':
        return colorNaranja;
      case 'Mantenimiento':
        return colorMorado;
      default:
        return colorAmarilloOscuro; // Cambiado de azul
    }
  }

  void _addQuestionFromTemplate(PreguntaTemplate template) {
    Navigator.pop(context);
    _preguntaController.text = template.texto;
    _categoryController.text = template.categoria;
    tipoRespuestaSeleccionado = template.tipoRespuesta;
    obligatoriaSeleccionada = template.obligatoria;
    if (template.opciones != null) {
      opcionesTemporales = template.opciones!
          .asMap()
          .entries
          .map((entry) => Opcion(valor: entry.value, orden: entry.key + 1))
          .toList();
    } else {
      opcionesTemporales.clear();
    }
    if (template.min != null) {
      _minController.text = template.min.toString();
    }
    if (template.max != null) {
      _maxController.text = template.max.toString();
    }
    _showPreguntaDialog();
  }

  void _showPreguntaDialog({Pregunta? pregunta}) {
    final isEditing = pregunta != null;
    if (isEditing) {
      _preguntaController.text = pregunta.texto;
      _categoryController.text = pregunta.categoria ?? '';
      tipoRespuestaSeleccionado = pregunta.tipoRespuesta ?? "texto";
      obligatoriaSeleccionada = pregunta.obligatoria;
      opcionesTemporales = List.from(pregunta.opciones ?? []);
      if (pregunta.tipoRespuesta == "numero") {
        _minController.text = pregunta.min?.toString() ?? '';
        _maxController.text = pregunta.max?.toString() ?? '';
      } else {
        _minController.clear();
        _maxController.clear();
      }
    } else if (!isEditing && _preguntaController.text.isEmpty) {
      _preguntaController.clear();
      _categoryController.clear();
      tipoRespuestaSeleccionado = "texto";
      obligatoriaSeleccionada = false;
      opcionesTemporales.clear();
      _minController.clear();
      _maxController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorNaranja, colorAmarillo],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Editar Pregunta' : 'Nueva Pregunta',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Modifica los campos necesarios'
                                  : 'Completa la información de la pregunta',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormSection(
                          'Pregunta',
                          Icons.quiz,
                          TextField(
                            controller: _preguntaController,
                            decoration: _buildInputDecoration(
                              'Escribe tu pregunta aquí...',
                              Icons.quiz,
                            ),
                            style: GoogleFonts.poppins(),
                            maxLines: 3,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildFormSection(
                          'Categoría',
                          Icons.category,
                          TextField(
                            controller: _categoryController,
                            decoration: _buildInputDecoration(
                              'Ej: Salud, Producción...',
                              Icons.category,
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildFormSection(
                          'Tipo de Respuesta',
                          Icons.category,
                          DropdownButtonFormField<String>(
                            value: tipoRespuestaSeleccionado,
                            decoration: _buildInputDecoration(
                              'Selecciona el tipo',
                              Icons.category,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: "texto",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      size: 16,
                                      color: colorAmarillo,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Texto libre",
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "numero",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.numbers,
                                      size: 16,
                                      color: colorNaranja,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Número",
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "opciones",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.list,
                                      size: 16,
                                      color: colorVerde,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Opciones múltiples",
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "rango",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.linear_scale,
                                      size: 16,
                                      color: colorMorado,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Rango (1-10)",
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                tipoRespuestaSeleccionado = value!;
                                if (value != "opciones") {
                                  opcionesTemporales.clear();
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: obligatoriaSeleccionada,
                                onChanged: (value) {
                                  setDialogState(() {
                                    obligatoriaSeleccionada = value ?? false;
                                  });
                                },
                                activeColor: colorVerde,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.priority_high,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pregunta obligatoria',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Los usuarios deberán responder esta pregunta',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (tipoRespuestaSeleccionado == "numero") ...[
                          SizedBox(height: 20),
                          _buildNumericRangeSection(setDialogState),
                        ],
                        if (tipoRespuestaSeleccionado == "opciones") ...[
                          SizedBox(height: 20),
                          _buildOptionsSection(setDialogState),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _savePregunta(pregunta),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorVerde,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                isEditing ? 'Actualizar' : 'Crear Pregunta',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: colorNaranja, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      prefixIcon: Icon(icon, color: colorNaranja),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorAmarillo, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildNumericRangeSection(StateSetter setDialogState) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorNaranja.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorNaranja.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: colorNaranja, size: 20),
              SizedBox(width: 8),
              Text(
                'Rango Numérico',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorNaranja,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Define los valores mínimo y máximo permitidos',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(
                    'Valor mínimo',
                    Icons.remove,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('Valor máximo', Icons.add),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(StateSetter setDialogState) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorVerde.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorVerde.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: colorVerde, size: 20),
              SizedBox(width: 8),
              Text(
                'Opciones de Respuesta',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorVerde,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Agrega las opciones que los usuarios podrán seleccionar',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          if (opcionesTemporales.isNotEmpty) ...[
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: opcionesTemporales.length,
                itemBuilder: (context, index) {
                  final opcion = opcionesTemporales[index];
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorVerde,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        opcion.valor,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            opcionesTemporales.removeAt(index);
                            for (
                              int i = 0;
                              i < opcionesTemporales.length;
                              i++
                            ) {
                              opcionesTemporales[i] = opcionesTemporales[i]
                                  .copyWith(orden: i + 1);
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _opcionController,
                  decoration: InputDecoration(
                    hintText: 'Escribe una nueva opción...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.add_circle_outline,
                      color: colorVerde,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorVerde, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 13),
                  onSubmitted: (value) => _addOpcion(setDialogState),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addOpcion(setDialogState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorVerde,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Agregar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (opcionesTemporales.isEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Sugerencias rápidas:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildQuickOption('Excelente', setDialogState),
                _buildQuickOption('Bueno', setDialogState),
                _buildQuickOption('Regular', setDialogState),
                _buildQuickOption('Malo', setDialogState),
                _buildQuickOption('Sí', setDialogState),
                _buildQuickOption('No', setDialogState),
              ],
            ),
          ],
          if (opcionesTemporales.length >= 2) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorAmarillo.withOpacity(0.1), // Cambiado de azul
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorAmarillo.withOpacity(0.3),
                ), // Cambiado de azul
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorAmarilloOscuro,
                    size: 16,
                  ), // Cambiado de azul
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${opcionesTemporales.length} opciones configuradas. Los usuarios podrán seleccionar una de estas opciones.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: colorAmarilloOscuro, // Cambiado de azul
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickOption(String text, StateSetter setDialogState) {
    return InkWell(
      onTap: () {
        _opcionController.text = text;
        _addOpcion(setDialogState);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorVerde.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 12, color: colorVerde),
        ),
      ),
    );
  }

  void _addOpcion(StateSetter setDialogState) {
    if (_opcionController.text.trim().isNotEmpty) {
      setDialogState(() {
        opcionesTemporales.add(
          Opcion(
            valor: _opcionController.text.trim(),
            orden: opcionesTemporales.length + 1,
          ),
        );
        _opcionController.clear();
      });
    }
  }

  Future<void> _savePregunta(Pregunta? pregunta) async {
    if (selectedApiarioId == null) {
      _showSnackBar('Por favor, selecciona un apiario primero.', Colors.red);
      return;
    }

    if (_preguntaController.text.trim().isEmpty) {
      _showSnackBar('La pregunta no puede estar vacía.', Colors.red);
      return;
    }

    if (tipoRespuestaSeleccionado == 'opciones' && opcionesTemporales.isEmpty) {
      _showSnackBar(
        'Las preguntas de opción requieren al menos una opción.',
        Colors.red,
      );
      return;
    }

    if (tipoRespuestaSeleccionado == 'numero' &&
        (_minController.text.isEmpty || _maxController.text.isEmpty)) {
      _showSnackBar(
        'Las preguntas numéricas requieren un rango min/max.',
        Colors.red,
      );
      return;
    }

    try {
      Navigator.pop(context); // Cerrar el diálogo

      final newQuestion = Pregunta(
        id: pregunta?.id ?? 0, // New ID will be assigned by backend
        apiarioId: selectedApiarioId!,
        texto: _preguntaController.text.trim(),
        tipoRespuesta: tipoRespuestaSeleccionado,
        categoria: _categoryController.text.trim(), // Guardar la categoría
        obligatoria: obligatoriaSeleccionada,
        opciones: opcionesTemporales.isNotEmpty ? opcionesTemporales : null,
        min: int.tryParse(_minController.text),
        max: int.tryParse(_maxController.text),
        orden: pregunta?.orden ?? (preguntas.length + 1),
        activa: pregunta?.activa ?? true,
        seleccionada: false, // Default value
      );

      if (pregunta == null) {
        await EnhancedApiService.crearPregunta(newQuestion);
        _showSnackBar('Pregunta creada correctamente', colorVerde);
      } else {
        await EnhancedApiService.actualizarPregunta(
          pregunta.id,
          newQuestion.toJson(),
        );
        _showSnackBar('Pregunta actualizada correctamente', colorVerde);
      }

      await _loadData();
    } catch (e) {
      _showSnackBar('Error al guardar pregunta: $e', Colors.red);
    }
  }

  void _duplicatePregunta(Pregunta pregunta) async {
    if (selectedApiarioId == null) {
      _showSnackBar(
        'Por favor, selecciona un apiario primero para duplicar.',
        Colors.red,
      );
      return;
    }

    try {
      final duplicatedQuestion = Pregunta(
        id: 0, // New ID will be assigned by backend
        apiarioId: selectedApiarioId!,
        texto: 'Copia de ${pregunta.texto}',
        tipoRespuesta: pregunta.tipoRespuesta,
        categoria: pregunta.categoria, // Duplicar la categoría
        obligatoria: pregunta.obligatoria,
        opciones: pregunta.opciones,
        min: pregunta.min,
        max: pregunta.max,
        orden: preguntas.length + 1, // Add to the end
        activa: true,
        seleccionada: false,
      );

      await EnhancedApiService.crearPregunta(duplicatedQuestion);
      _showSnackBar('Pregunta duplicada correctamente', colorVerde);
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al duplicar pregunta: $e', Colors.red);
    }
  }

  void _confirmDeletePregunta(Pregunta pregunta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la pregunta "${pregunta.texto}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePregunta(pregunta.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePregunta(int preguntaId) async {
    try {
      await EnhancedApiService.eliminarPregunta(preguntaId);
      _showSnackBar('Pregunta eliminada correctamente', colorVerde);
      await _loadData();
    } catch (e) {
      _showSnackBar('Error al eliminar pregunta: $e', Colors.red);
    }
  }

  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando datos...", colorAmarillo);
      await _checkConnection();
      if (isConnected) {
        await _loadData();
        _showSnackBar("Datos sincronizados correctamente", colorVerde);
      } else {
        _showSnackBar("Sin conexión a internet", colorNaranja);
      }
    } catch (e) {
      _showSnackBar("Error en sincronización: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _preguntaController.dispose();
    _opcionController.dispose();
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _bankSearchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
