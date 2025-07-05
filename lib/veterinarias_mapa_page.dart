import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';

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
        title: const Text('Permiso de ubicación requerido'),
        content: const Text(
          'Para mostrar veterinarias cercanas, necesitamos acceso a tu ubicación. Por favor, activa el permiso en la configuración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
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

    print('Buscando veterinarias...');
    await _buscarVeterinarias();
  } catch (e) {
    print('ERROR al obtener ubicación: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
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
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Verificar si hay token antes de hacer la petición
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      print('ERROR: No se encontró token JWT');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión expirada. Por favor, inicia sesión nuevamente.')),
        );
      }
      return;
    }

    const baseUrl = 'https://patitas-care.onrender.com';
    final url = '$baseUrl/veterinarias/cercanas?'
        'latitud=${_currentPosition!.latitude}&'
        'longitud=${_currentPosition!.longitude}&'
        'radio=$_radioSeleccionado';

    print('URL de la petición: $url');
    print('Token disponible: Sí');

    // Usar el método authenticatedGet del AuthService
    final response = await AuthService.authenticatedGet(url).timeout(
      const Duration(seconds: 15),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Datos recibidos: ${data.length} veterinarias');
      
      setState(() {
        _veterinarias = data
            .map((json) => VeterinariaResponse.fromJson(json))
            .toList();
      });
      
      print('Veterinarias procesadas: ${_veterinarias.length}');
      
      if (_veterinarias.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron veterinarias en el radio seleccionado')),
          );
        }
      }
    } else if (response.statusCode == 401) {
      print('ERROR 401: Token inválido o expirado');
      // Limpiar token expirado
      await AuthService.removeToken();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión expirada. Por favor, inicia sesión nuevamente.')),
        );
      }
      // Redirigir al login si tienes la ruta configurada
      // Navigator.pushReplacementNamed(context, '/login');
    } else if (response.statusCode == 403) {
      print('ERROR 403: Acceso denegado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para acceder a esta información.')),
        );
      }
    } else if (response.statusCode == 404) {
      print('ERROR 404: Endpoint no encontrado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio no disponible. Verifica la URL.')),
        );
      }
    } else {
      print('ERROR: Status code ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener veterinarias: ${response.statusCode}')),
        );
      }
    }
  } catch (e) {
    print('ERROR de conexión: $e');
    print('Stack trace: ${StackTrace.current}');
    
    if (mounted) {
      String errorMessage = 'Error de conexión';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'La conexión tardó demasiado. Verifica tu internet.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Sin conexión a internet';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _llamarVeterinaria(String telefono) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede realizar la llamada')),
        );
      }
    }
  }

  Future<void> _abrirDirecciones(double lat, double lng) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se puede abrir el mapa')),
        );
      }
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                const Icon(Icons.local_hospital, 
                    color: Color(0xFFB6A9F8), size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    veterinaria.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            _buildDetailRow(Icons.location_on, veterinaria.direccion),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.phone, veterinaria.telefono),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.access_time, veterinaria.horario),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.straighten, 
                '${veterinaria.distancia.toStringAsFixed(1)} km'),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.category, veterinaria.tipo),
            
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _llamarVeterinaria(veterinaria.telefono),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Llamar', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6A9F8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirDirecciones(
                        veterinaria.latitud, veterinaria.longitud),
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text('Ir', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB6A9F8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Radio: ', style: TextStyle(fontSize: 16)),
          DropdownButton<int>(
            value: _radioSeleccionado,
            items: [5, 10, 15, 20].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value km'),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _radioSeleccionado = newValue;
                });
                _buscarVeterinarias();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapa() {
    if (_currentPosition == null) {
      return const Center(
        child: Text('Obteniendo ubicación...'),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.patitas_care',
        ),
        MarkerLayer(
          markers: [
            // Marcador de ubicación actual
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 40,
              ),
            ),
            // Marcadores de veterinarias
            ..._veterinarias.map((veterinaria) {
              return Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(veterinaria.latitud, veterinaria.longitud),
                child: GestureDetector(
                  onTap: () => _mostrarDetallesVeterinaria(veterinaria),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Color(0xFFB6A9F8),
                    size: 40,
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
        child: Text(
          'No se encontraron veterinarias cercanas',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _veterinarias.length,
      itemBuilder: (context, index) {
        final veterinaria = _veterinarias[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFB6A9F8),
              child: Icon(Icons.local_hospital, color: Colors.white),
            ),
            title: Text(
              veterinaria.nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(veterinaria.direccion),
                const SizedBox(height: 4),
                Text(
                  '${veterinaria.distancia.toStringAsFixed(1)} km • ${veterinaria.tipo}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'llamar':
                    _llamarVeterinaria(veterinaria.telefono);
                    break;
                  case 'direcciones':
                    _abrirDirecciones(veterinaria.latitud, veterinaria.longitud);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'llamar',
                  child: Row(
                    children: [
                      Icon(Icons.phone),
                      SizedBox(width: 8),
                      Text('Llamar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'direcciones',
                  child: Row(
                    children: [
                      Icon(Icons.directions),
                      SizedBox(width: 8),
                      Text('Ir'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _mostrarDetallesVeterinaria(veterinaria),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB6A9F8),
        foregroundColor: Colors.white,
        title: const Text('Veterinarias Cercanas'),
        actions: [
          IconButton(
            icon: Icon(_vistaLista ? Icons.map : Icons.list),
            onPressed: () {
              setState(() {
                _vistaLista = !_vistaLista;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _buscarVeterinarias,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRadioSelector(),
          
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB6A9F8)),
            ),
          
          Expanded(
            child: _locationPermissionGranted
                ? (_vistaLista ? _buildLista() : _buildMapa())
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_disabled, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Se necesita permiso de ubicación',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}