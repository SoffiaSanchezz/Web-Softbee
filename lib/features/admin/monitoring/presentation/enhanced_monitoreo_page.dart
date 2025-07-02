import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/models/enhanced_models.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/apiary_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhanced_voice_assistant_service.dart';
import 'package:sotfbee/features/admin/monitoring/service/local_db_service.dart';


class EnhancedMonitoreoScreen extends StatefulWidget {
  const EnhancedMonitoreoScreen({Key? key}) : super(key: key);

  @override
  _EnhancedMonitoreoScreenState createState() =>
      _EnhancedMonitoreoScreenState();
}

class _EnhancedMonitoreoScreenState extends State<EnhancedMonitoreoScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Servicios
  late EnhancedVoiceAssistantService mayaAssistant;
  late LocalDBService dbService;

  // Controladores de animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Estado de la aplicación
  bool isInitialized = false;
  bool isConnected = false;
  String connectionStatus = "Verificando conexión...";

  // Estado de Maya
  bool isMayaActive = false;
  bool isMayaListening = false;
  String mayaStatus = "Maya desactivada";
  List<MonitoreoRespuesta> currentResponses = [];

  // Datos
  List<Apiario> apiarios = [];
  List<Colmena> colmenas = [];
  Map<String, dynamic> estadisticas = {};
  Apiario? selectedApiario;

  // Colores
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorAmbarMedio = const Color(0xFFFFE082);
  final Color colorVerde = const Color(0xFF4CAF50);
  final Color colorRojo = const Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeServices();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    try {
      dbService = LocalDBService();
      await _loadInitialData();
      mayaAssistant = EnhancedVoiceAssistantService(apiarios: apiarios);
      _setupMayaListeners();
      await mayaAssistant.initialize();
      await _checkConnection();

      setState(() {
        isInitialized = true;
      });

      _showSnackBar("Sistema inicializado correctamente", colorVerde);
    } catch (e) {
      debugPrint("❌ Error al inicializar servicios: $e");
      _showSnackBar("Error al inicializar: $e", colorRojo);
    }
  }

  void _setupMayaListeners() {
    mayaAssistant.statusController.stream.listen((status) {
      if (mounted) {
        setState(() {
          mayaStatus = status;
        });
      }
    });

    mayaAssistant.listeningController.stream.listen((listening) {
      if (mounted) {
        setState(() {
          isMayaListening = listening;
        });
      }
    });

    mayaAssistant.speechResultsController.stream.listen((result) {
      if (mounted) {
        setState(() {
          isMayaActive = mayaAssistant.isAssistantActive;
          currentResponses = mayaAssistant.currentResponses;
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      apiarios = await EnhancedApiService.obtenerApiarios();
      estadisticas = await EnhancedApiService.obtenerEstadisticas();
      setState(() {});
      debugPrint("✅ Datos iniciales cargados");
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
      _showSnackBar("Error al cargar apiarios: $e", colorRojo);
    }
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await EnhancedApiService.verificarConexion();
      setState(() {
        isConnected = connected;
        connectionStatus = connected ? "Conectado al servidor" : "Modo offline";
      });
    } catch (e) {
      setState(() {
        isConnected = false;
        connectionStatus = "Sin conexión";
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    mayaAssistant.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      mayaAssistant.stopAssistant();
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: _buildAppBar(isDesktop, isTablet),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildBody(isDesktop, isTablet, screenHeight),
            ),
          ),
        ),
      ),
      floatingActionButton: apiarios.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApiariosManagementScreen(),
                  ),
                ).then((_) => _loadInitialData());
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Agregar Apiario',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: colorVerde,
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop, bool isTablet) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.hive, color: Colors.white, size: isDesktop ? 28 : 24),
          SizedBox(width: 12),
          Text(
            'Monitoreo Inteligente',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : 20,
              color: Colors.white,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
      backgroundColor: colorNaranja,
      elevation: 0,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? colorVerde : colorRojo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                isConnected ? "Online" : "Offline",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).scale(),
        IconButton(
          icon: Icon(Icons.sync, color: Colors.white),
          onPressed: _syncData,
          tooltip: "Sincronizar datos",
        ).animate().fadeIn(delay: 400.ms).scale(),
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettingsDialog(),
          tooltip: "Configuración",
        ).animate().fadeIn(delay: 600.ms).scale(),
      ],
    );
  }

  Widget _buildBody(bool isDesktop, bool isTablet, double screenHeight) {
    if (!isInitialized) {
      return _buildLoadingScreen();
    }

    return Column(
      children: [
        // Selector de Apiario
        _buildApiarioSelector(isDesktop, isTablet),

        // Maya Button Central
        Expanded(
          child: _buildMayaCentralSection(isDesktop, isTablet, screenHeight),
        ),

        // Estadísticas en la parte inferior
        _buildBottomStats(isDesktop, isTablet),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorAmarillo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hive, size: 64, color: colorNaranja),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 2000.ms),
          SizedBox(height: 24),
          Text(
            "Inicializando Maya...",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorNaranja,
            ),
          ),
          SizedBox(height: 12),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorAmarillo),
          ),
        ],
      ),
    );
  }

  Widget _buildApiarioSelector(bool isDesktop, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selectedApiario != null ? colorVerde : colorAmarillo,
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: colorNaranja, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Selecciona tu Apiario",
                    style: GoogleFonts.poppins(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: colorNaranja,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (apiarios.isEmpty)
                Container(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.location_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "No hay apiarios configurados",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ApiariosManagementScreen(),
                              ),
                            ).then((_) => _loadInitialData());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorVerde,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Agregar Apiario",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: apiarios.length,
                    itemBuilder: (context, index) {
                      final apiario = apiarios[index];
                      final isSelected = selectedApiario?.id == apiario.id;

                      return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedApiario = apiario;
                              });
                              _showSnackBar(
                                "Apiario ${apiario.nombre} seleccionado",
                                colorVerde,
                              );
                            },
                            child: Container(
                              width: 160,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorVerde.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? colorVerde
                                      : colorAmbarMedio,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorVerde
                                            : colorAmarillo,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.hive,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      apiario.nombre,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: isSelected
                                            ? colorVerde
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      apiario.ubicacion,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 200 + (index * 100)),
                          )
                          .scale();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildMayaCentralSection(
    bool isDesktop,
    bool isTablet,
    double screenHeight,
  ) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selectedApiario != null) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorVerde.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorVerde, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Apiario Seleccionado",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorVerde,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectedApiario!.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    selectedApiario!.ubicacion,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
          GestureDetector(
            onTap: selectedApiario != null
                ? (isMayaActive ? _stopMaya : _startMaya)
                : () => _showSnackBar(
                    "Primero selecciona un apiario",
                    Colors.orange,
                  ),
            child:
                Container(
                      width: isDesktop
                          ? 200
                          : isTablet
                          ? 180
                          : 160,
                      height: isDesktop
                          ? 200
                          : isTablet
                          ? 180
                          : 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: selectedApiario == null
                              ? [Colors.grey.shade300, Colors.grey.shade400]
                              : isMayaActive
                              ? [colorRojo, colorRojo.withOpacity(0.8)]
                              : [colorVerde, colorVerde.withOpacity(0.8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedApiario == null
                                ? Colors.grey.withOpacity(0.3)
                                : (isMayaActive ? colorRojo : colorVerde)
                                      .withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: isDesktop
                                ? 160
                                : isTablet
                                ? 140
                                : 120,
                            height: isDesktop
                                ? 160
                                : isTablet
                                ? 140
                                : 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          Icon(
                            selectedApiario == null
                                ? Icons.lock
                                : isMayaListening
                                ? Icons.mic
                                : isMayaActive
                                ? Icons.stop
                                : Icons.mic,
                            size: isDesktop
                                ? 80
                                : isTablet
                                ? 70
                                : 60,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    )
                    .animate(
                      onPlay: (controller) => isMayaListening
                          ? controller.repeat(reverse: true)
                          : null,
                    )
                    .scale(
                      begin: Offset(1, 1),
                      end: Offset(1.1, 1.1),
                      duration: 1000.ms,
                    ),
          ),
          SizedBox(height: 24),
          Text(
            selectedApiario == null
                ? "Selecciona un apiario"
                : isMayaActive
                ? "Toca para detener"
                : "Toca para iniciar",
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: selectedApiario == null ? Colors.grey : colorNaranja,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            "Maya - Asistente de Voz",
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 16 : 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          if (isMayaActive && currentResponses.isNotEmpty) ...[
            SizedBox(height: 24),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              constraints: BoxConstraints(maxHeight: 150),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Respuestas recientes:",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: colorNaranja,
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentResponses.length,
                          itemBuilder: (context, index) {
                            final resp = currentResponses[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 4),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorAmbarClaro,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${resp.preguntaTexto}: ${resp.respuesta}",
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomStats(bool isDesktop, bool isTablet) {
    final stats = [
      {
        'title': 'Apiarios',
        'value': estadisticas['total_apiarios']?.toString() ?? '0',
        'icon': Icons.location_on,
        'color': colorVerde,
      },
      {
        'title': 'Colmenas',
        'value': estadisticas['total_colmenas']?.toString() ?? '0',
        'icon': Icons.hive,
        'color': colorAmarillo,
      },
      {
        'title': 'Monitoreos',
        'value': estadisticas['total_monitoreos']?.toString() ?? '0',
        'icon': Icons.analytics,
        'color': colorNaranja,
      },
    ];

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      size: 24,
                      color: stat['color'] as Color,
                    ),
                    SizedBox(height: 4),
                    Text(
                      stat['value'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    Text(
                      stat['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _startMaya() async {
    if (selectedApiario == null) {
      _showSnackBar("Primero selecciona un apiario", Colors.orange);
      return;
    }

    try {
      await mayaAssistant.startMonitoringFlow();
      setState(() {
        isMayaActive = true;
      });
      _showSnackBar(
        "Maya activada - Monitoreando ${selectedApiario!.nombre}",
        colorVerde,
      );
    } catch (e) {
      _showSnackBar("Error al activar Maya: $e", colorRojo);
    }
  }

  Future<void> _stopMaya() async {
    try {
      await mayaAssistant.stopAssistant();
      setState(() {
        isMayaActive = false;
        isMayaListening = false;
      });
      _showSnackBar("Maya desactivada", Colors.grey);
    } catch (e) {
      _showSnackBar("Error al detener Maya: $e", colorRojo);
    }
  }

  Future<void> _syncData() async {
    try {
      _showSnackBar("Sincronizando datos...", colorAmarillo);
      await _checkConnection();

      if (!isConnected) {
        _showSnackBar(
          "Sin conexión - Los datos se sincronizarán automáticamente",
          Colors.orange,
        );
        return;
      }

      await _loadInitialData();
      _showSnackBar("Datos sincronizados correctamente", colorVerde);
    } catch (e) {
      _showSnackBar("Error en sincronización: $e", colorRojo);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Configuración",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.mic),
              title: Text("Configurar Maya"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.sync),
              title: Text("Configurar sincronización"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.storage),
              title: Text("Gestionar datos locales"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cerrar"),
          ),
        ],
      ),
    );
  }
}
