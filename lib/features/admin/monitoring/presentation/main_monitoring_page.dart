import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/apiary_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/queen_calendar_page.dart';
import 'package:sotfbee/features/admin/monitoring/presentation/question_management_page.dart';
import 'package:sotfbee/features/admin/monitoring/service/enhaced_api_service.dart';
import 'package:sotfbee/features/admin/monitoring/service/voice_alert_service.dart';
import 'package:sotfbee/features/admin/monitoring/widgets/enhanced_card_widget.dart';
import '../models/enhanced_models.dart';


class MainMonitoringScreen extends StatefulWidget {
  const MainMonitoringScreen({Key? key}) : super(key: key);

  @override
  _MainMonitoringScreenState createState() => _MainMonitoringScreenState();
}

class _MainMonitoringScreenState extends State<MainMonitoringScreen>
    with SingleTickerProviderStateMixin {
  
  // Estado
  bool isLoading = true;
  bool isConnected = false;
  Map<String, dynamic> estadisticas = {};
  List<Apiario> apiarios = [];

  // Colores
  final Color colorAmarillo = const Color(0xFFFBC209);
  final Color colorNaranja = const Color(0xFFFF9800);
  final Color colorAmbarClaro = const Color(0xFFFFF8E1);
  final Color colorVerde = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _loadData();
      await _checkConnection();
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

  Future<void> _loadData() async {
    try {
      estadisticas = await EnhancedApiService.obtenerEstadisticas();
      apiarios = await EnhancedApiService.obtenerApiarios();
      setState(() {});
    } catch (e) {
      debugPrint("❌ Error al cargar datos: $e");
    }
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await EnhancedApiService.verificarConexion();
      setState(() {
        isConnected = connected; // Corregido aquí
      });
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    if (isLoading) {
      return Scaffold(
        backgroundColor: colorAmbarClaro,
        body: LoadingWidget(
          message: "Cargando sistema...",
          color: colorNaranja,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorAmbarClaro,
      appBar: CustomAppBarWidget(
        title: 'Sistema de Monitoreo',
        isConnected: isConnected,
        onSync: _syncData,
      ),
      body: SafeArea(
        child: _buildBody(isTablet),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => VoiceAlertService.showVoiceFeatureAlert(context),
        backgroundColor: colorNaranja,
        icon: Icon(Icons.mic, color: Colors.white),
        label: Text(
          'Maya',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().scale(delay: 1000.ms),
    );
  }

  Widget _buildBody(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas principales
          _buildStatsGrid(isTablet),
          SizedBox(height: 20),
          // Menú principal de opciones
          _buildMainMenu(isTablet),
          SizedBox(height: 20),
          // Acciones rápidas
          _buildQuickActions(isTablet),
          SizedBox(height: 20),
          // Lista de apiarios recientes
          _buildRecentApiarios(isTablet),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: StatCardWidget(
            label: 'Apiarios',
            value: estadisticas['total_apiarios']?.toString() ?? '0',
            icon: Icons.location_on,
            color: colorVerde,
            animationDelay: 0,
            onTap: () => _navigateToApiarios(),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCardWidget(
            label: 'Colmenas',
            value: estadisticas['total_colmenas']?.toString() ?? '0',
            icon: Icons.hive,
            color: colorAmarillo,
            animationDelay: 100,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCardWidget(
            label: 'Monitoreos',
            value: estadisticas['total_monitoreos']?.toString() ?? '0',
            icon: Icons.analytics,
            color: colorNaranja,
            animationDelay: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu(bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, colorAmbarClaro.withOpacity(0.3)],
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorNaranja.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.menu, color: colorNaranja, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  "Menú Principal",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorNaranja,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Column(
              children: [
                EnhancedCardWidget(
                  title: "Gestionar Apiarios",
                  subtitle: "CRUD completo de apiarios",
                  icon: Icons.location_city,
                  color: colorVerde,
                  onTap: () => _navigateToApiarios(),
                  animationDelay: 300,
                  showBorder: true,
                ),
                SizedBox(height: 6),
                EnhancedCardWidget(
                  title: "Preguntas de Monitoreo",
                  subtitle: "Gestionar y reordenar preguntas",
                  icon: Icons.quiz,
                  color: colorAmarillo,
                  onTap: () => _navigateToPreguntas(),
                  animationDelay: 400,
                  showBorder: true,
                ),
                SizedBox(height: 6),
                EnhancedCardWidget(
                  title: "Calendario de Reinas",
                  subtitle: "Programar cambios de reina",
                  icon: Icons.calendar_month,
                  color: Colors.purple,
                  onTap: () => _navigateToCalendar(),
                  animationDelay: 500,
                  showBorder: true,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(bool isTablet) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorVerde.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.flash_on, color: colorVerde, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  "Acciones Rápidas",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorVerde,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionButtonWidget(
                  label: "Asistente Maya",
                  icon: Icons.mic,
                  color: colorNaranja,
                  onPressed: () => VoiceAlertService.showVoiceFeatureAlert(context),
                ),
                ActionButtonWidget(
                  label: "Sincronizar",
                  icon: Icons.sync,
                  color: colorVerde,
                  onPressed: () => _syncData(),
                ),
                ActionButtonWidget(
                  label: "Historial",
                  icon: Icons.history,
                  color: colorAmarillo,
                  onPressed: () => _showHistory(),
                ),
                ActionButtonWidget(
                  label: "Configuración",
                  icon: Icons.settings,
                  color: Colors.grey[600]!,
                  onPressed: () => _showSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecentApiarios(bool isTablet) {
    if (apiarios.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.location_off,
        title: 'No hay apiarios',
        subtitle: 'Crea tu primer apiario para comenzar con el monitoreo',
        actionText: 'Crear Apiario',
        onAction: () => _navigateToApiarios(),
        color: colorNaranja,
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorAmarillo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on, color: colorAmarillo, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  "Apiarios Recientes",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorAmarillo,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () => _navigateToApiarios(),
                  child: Text(
                    'Ver todos',
                    style: GoogleFonts.poppins(
                      color: colorNaranja,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: apiarios.take(3).length,
              itemBuilder: (context, index) {
                final apiario = apiarios[index];
                return EnhancedCardWidget(
                  title: apiario.nombre,
                  subtitle: apiario.ubicacion,
                  icon: Icons.location_on,
                  color: colorVerde,
                  animationDelay: 800 + (index * 100),
                  onTap: () => _showApiarioDetails(apiario),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0);
  }

  // Métodos de navegación
  void _navigateToApiarios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ApiariosManagementScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToPreguntas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuestionsManagementScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QueenCalendarScreen()),
    );
  }

  // Métodos de acción
  Future<void> _syncData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sincronizando datos...", style: GoogleFonts.poppins()),
          backgroundColor: colorAmarillo,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      await _checkConnection();
      if (isConnected) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Datos sincronizados correctamente", style: GoogleFonts.poppins()),
            backgroundColor: colorVerde,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sin conexión a internet", style: GoogleFonts.poppins()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error en sincronización: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Función de historial en desarrollo", style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Configuración",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.sync, color: colorNaranja),
              title: Text("Configurar sincronización", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.storage, color: colorVerde),
              title: Text("Gestionar datos", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: colorAmarillo),
              title: Text("Acerca de", style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: GoogleFonts.poppins(
                color: colorNaranja,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiarioDetails(Apiario apiario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          apiario.nombre,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Ubicación:', apiario.ubicacion),
            _buildDetailRow('ID:', apiario.id.toString()),
            if (apiario.fechaCreacion != null)
              _buildDetailRow(
                'Fecha de creación:',
                '${apiario.fechaCreacion!.day}/${apiario.fechaCreacion!.month}/${apiario.fechaCreacion!.year}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(
                color: colorNaranja,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToApiarios();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorVerde,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Gestionar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.hive, color: colorNaranja),
            SizedBox(width: 12),
            Text(
              "SoftBee",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sistema de Monitoreo de Colmenas",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Versión 2.0.0",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              "Aplicación desarrollada para facilitar el monitoreo y gestión de apiarios de manera eficiente y moderna.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: GoogleFonts.poppins(
                color: colorNaranja,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}