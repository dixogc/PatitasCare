import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:patitas_care/inicio_page.dart';
import 'package:patitas_care/notification_helper.dart';
import 'package:patitas_care/success_feedback_widget.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

class VeterinariaResponse {
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final String telefono;
  final String horario;
  final double distancia;
  final String tipo;

  VeterinariaResponse({
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.telefono,
    required this.horario,
    required this.distancia,
    required this.tipo,
  });

  factory VeterinariaResponse.fromJson(Map<String, dynamic> json) {
    return VeterinariaResponse(
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      telefono: json['telefono'] ?? '',
      horario: json['horario'] ?? '',
      distancia: (json['distancia'] ?? 0.0).toDouble(),
      tipo: json['tipo'] ?? '',
    );
  }
}

class VeterinariasMapaPage extends StatefulWidget {
  const VeterinariasMapaPage({super.key});

  @override
  _VeterinariasMapaPageState createState() => _VeterinariasMapaPageState();
}

class _VeterinariasMapaPageState extends State<VeterinariasMapaPage> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<VeterinariaResponse> _veterinarias = [];
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  int _radioSeleccionado = 10;
  bool _vistaLista = false;
  bool _showSuccessFeedback = false;

  // Colores del tema de la app
  final Color purple = const Color(0xFF8F88F2);
  final Color yellow = const Color(0xFFF9DC5C);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        _locationPermissionGranted = true;
      });
      _getCurrentLocation();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Permiso de ubicación requerido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Para mostrar veterinarias cercanas, necesitamos acceso a tu ubicación. Por favor, activa el permiso en la configuración.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Obteniendo ubicación...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
      });

      context.showSuccessNotification('Ubicación obtenida correctamente');
      print('Buscando veterinarias...');
      await _buscarVeterinarias();
    } catch (e) {
      print('ERROR al obtener ubicación: $e');

      if (mounted) {
        String errorMessage = 'Error al obtener ubicación';
        if (e.toString().contains('LocationServiceDisabledException')) {
          errorMessage = 'Los servicios de ubicación están desactivados';
        } else if (e.toString().contains('PermissionDeniedException')) {
          errorMessage = 'Permiso de ubicación denegado';
        }

        context.showErrorNotification(
          errorMessage,
          actionLabel: 'Reintentar',
          onAction: () => _getCurrentLocation(),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarVeterinarias() async {
    if (_currentPosition == null) {
      print('ERROR: _currentPosition es null');
      context.showErrorNotification('No se pudo obtener la ubicación');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      context.showInfoNotification('Buscando veterinarias cercanas...');

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        print('ERROR: No se encontró token JWT');
        if (mounted) {
          context.showErrorNotification(
            'Sesión expirada',
            actionLabel: 'Iniciar sesión',
            onAction: () {
              // Navegar a login
              Navigator.pushReplacementNamed(context, '/login');
            },
          );
        }
        return;
      }

      const baseUrl = 'https://patitas-care.onrender.com';
      final url =
          '$baseUrl/veterinarias/cercanas?'
          'latitud=${_currentPosition!.latitude}&'
          'longitud=${_currentPosition!.longitude}&'
          'radio=$_radioSeleccionado';

      print('URL de la petición: $url');

      final response = await AuthService.authenticatedGet(url).timeout(const Duration(seconds: 30));

      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Datos recibidos: ${data.length} veterinarias');

        setState(() {
          _veterinarias = data
              .map((json) => VeterinariaResponse.fromJson(json))
              .toList();
        });

        if (_veterinarias.isEmpty) {
          if (mounted) {
            context.showWarningNotification(
              'No se encontraron veterinarias en un radio de $_radioSeleccionado km',
              actionLabel: 'Ampliar búsqueda',
              onAction: () {
                setState(() {
                  _radioSeleccionado = _radioSeleccionado < 20 ? _radioSeleccionado + 5 : 25;
                });
                _buscarVeterinarias();
              },
            );
          }
        } else {
          // Mostrar feedback de éxito
          setState(() {
            _showSuccessFeedback = true;
          });
          
          context.showSuccessNotification(
            'Se encontraron ${_veterinarias.length} veterinarias cercanas',
          );
        }
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      print('ERROR de conexión: $e');
      if (mounted) {
        String errorMessage = 'Error de conexión';
        String? actionLabel;
        VoidCallback? onAction;

        if (e.toString().contains('TimeoutException')) {
          errorMessage = 'La conexión tardó demasiado';
          actionLabel = 'Reintentar';
          onAction = () => _buscarVeterinarias();
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'Sin conexión a internet';
          actionLabel = 'Verificar';
          onAction = () {
            // Aquí podrías abrir configuración de red o reintentar
            _buscarVeterinarias();
          };
        }

        context.showErrorNotification(
          errorMessage,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleErrorResponse(http.Response response) {
    String message = 'Error desconocido';
    String? actionLabel;
    VoidCallback? onAction;

    switch (response.statusCode) {
      case 401:
        message = 'Sesión expirada';
        actionLabel = 'Iniciar sesión';
        onAction = () {
          AuthService.removeToken();
          Navigator.pushReplacementNamed(context, '/login');
        };
        break;
      case 403:
        message = 'No tienes permisos para acceder a esta información';
        break;
      case 404:
        message = 'Servicio no disponible temporalmente';
        actionLabel = 'Reintentar';
        onAction = () => _buscarVeterinarias();
        break;
      case 500:
      case 502:
      case 503:
        message = 'Error del servidor';
        actionLabel = 'Reintentar';
        onAction = () => _buscarVeterinarias();
        break;
      default:
        message = 'Error inesperado (${response.statusCode})';
        actionLabel = 'Reintentar';
        onAction = () => _buscarVeterinarias();
    }

    if (mounted) {
      context.showErrorNotification(
        message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }
  }

  Future<void> _llamarVeterinaria(String telefono) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: telefono);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        context.showSuccessNotification('Abriendo aplicación de teléfono...');
      } else {
        context.showErrorNotification('No se puede realizar la llamada');
      }
    } catch (e) {
      context.showErrorNotification('Error al intentar llamar');
    }
  }

  Future<void> _abrirDirecciones(double lat, double lng) async {
    try {
      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      );
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        context.showSuccessNotification('Abriendo navegación...');
      } else {
        context.showErrorNotification('No se puede abrir el mapa');
      }
    } catch (e) {
      context.showErrorNotification('Error al abrir la navegación');
    }
  }

  void _mostrarDetallesVeterinaria(VeterinariaResponse veterinaria) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    veterinaria.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildDetailRow(Icons.location_on, veterinaria.direccion),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.phone, veterinaria.telefono),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, veterinaria.horario),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.straighten,
              '${veterinaria.distancia.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.category, veterinaria.tipo),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _llamarVeterinaria(veterinaria.telefono);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 20),
                        SizedBox(width: 8),
                        Text('Llamar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _abrirDirecciones(
                        veterinaria.latitud,
                        veterinaria.longitud,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions, size: 20),
                        SizedBox(width: 8),
                        Text('Ir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Radio de búsqueda: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButton<int>(
              value: _radioSeleccionado,
              underline: const SizedBox(),
              items: [5, 10, 15, 20, 25].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _radioSeleccionado = newValue;
                  });
                  context.showInfoNotification('Buscando en radio de $newValue km...');
                  _buscarVeterinarias();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F88F2)),
            ),
            SizedBox(height: 16),
            Text(
              'Obteniendo ubicación...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.patitas_care',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40.0,
              height: 40.0,
              point: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            ..._veterinarias.map((veterinaria) {
              return Marker(
                width: 50.0,
                height: 50.0,
                point: LatLng(veterinaria.latitud, veterinaria.longitud),
                child: GestureDetector(
                  onTap: () => _mostrarDetallesVeterinaria(veterinaria),
                  child: Container(
                    decoration: BoxDecoration(
                      color: purple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: purple.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildLista() {
    if (_veterinarias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron veterinarias cercanas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _veterinarias.length,
      itemBuilder: (context, index) {
        final veterinaria = _veterinarias[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _mostrarDetallesVeterinaria(veterinaria),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        color: purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            veterinaria.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            veterinaria.direccion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${veterinaria.distancia.toStringAsFixed(1)} km • ${veterinaria.tipo}',
                            style: TextStyle(
                              fontSize: 14,
                              color: purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'llamar':
                            _llamarVeterinaria(veterinaria.telefono);
                            break;
                          case 'direcciones':
                            _abrirDirecciones(
                              veterinaria.latitud,
                              veterinaria.longitud,
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'llamar',
                          child: Row(
                            children: [
                              Icon(Icons.phone, color: Colors.black54),
                              SizedBox(width: 12),
                              Text('Llamar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'direcciones',
                          child: Row(
                            children: [
                              Icon(Icons.directions, color: Colors.black54),
                              SizedBox(width: 12),
                              Text('Ir'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuccessFeedbackWidget(
      showSuccess: _showSuccessFeedback,
      successMessage: '¡Veterinarias encontradas!',
      onComplete: () {
        setState(() {
          _showSuccessFeedback = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Fondo decorativo
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: yellow.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: yellow.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(75),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => InicioPage())
                          ),
                          icon: const Icon(Icons.arrow_back, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Veterinarias Cercanas',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _vistaLista ? Icons.map : Icons.list,
                              color: purple,
                            ),
                            onPressed: () {
                              setState(() {
                                _vistaLista = !_vistaLista;
                              });
                              context.showInfoNotification(
                                _vistaLista 
                                  ? 'Cambiando a vista de lista' 
                                  : 'Cambiando a vista de mapa'
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.refresh, color: purple),
                            onPressed: () {
                              context.showInfoNotification('Actualizando ubicaciones...');
                              _buscarVeterinarias();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildRadioSelector(),

                  if (_isLoading)
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(purple),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                  Expanded(
                    child: _locationPermissionGranted
                        ? (_vistaLista ? _buildLista() : _buildMapa())
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_disabled,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Se necesita permiso de ubicación',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    context.showInfoNotification('Solicitando permisos...');
                                    _requestLocationPermission();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text('Solicitar Permiso'),
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
    );
  }
}