import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';

class HistorialMedicoPage extends StatefulWidget {
  const HistorialMedicoPage({super.key});

  @override
  _HistorialMedicoPageState createState() => _HistorialMedicoPageState();
}

class _HistorialMedicoPageState extends State<HistorialMedicoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mascotaIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedTipo = 'VACUNACION';

  List<Map<String, dynamic>> _registros = [];

  final List<String> tipos = [
    'VACUNACION',
    'CIRUGIA',
    'DESPARASITACION',
    'OTRO',
  ];

  Future<void> _addRecord() async {
    if (_formKey.currentState!.validate()) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final newRecord = {
        'mascotaId': _mascotaIdController.text.trim(),
        'fecha': formattedDate,
        'titulo': _titleController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'tipo': _selectedTipo,
      };

      try {
        final response = await AuthService.authenticatedPost(
          'https://patitas-care.onrender.com/historial-medico',
          body: newRecord,
        );

        if (response.statusCode == 201) {
          setState(() {
            _registros.add(newRecord);
            _mascotaIdController.clear();
            _titleController.clear();
            _descriptionController.clear();
            _selectedTipo = 'VACUNACION';
            _selectedDate = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro agregado con éxito')),
          );
        } else {
          print('Error al guardar en backend: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${response.body}')),
          );
        }
      } catch (e) {
        print('Excepción al guardar: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Médico'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _mascotaIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID de la mascota',
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese el ID de la mascota' : null,
                  ),
                  Row(
                    children: [
                      Text(
                        'Fecha: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedTipo,
                    items: tipos.map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTipo = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese un título' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese una descripción' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _addRecord,
                    child: const Text('Agregar Registro'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Registros agregados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: _registros.isEmpty
                  ? const Center(child: Text('No hay registros aún.'))
                  : ListView.builder(
                      itemCount: _registros.length,
                      itemBuilder: (context, index) {
                        final record = _registros[index];
                        return Card(
                          child: ListTile(
                            title: Text(record['titulo']),
                            subtitle: Text(
                              'Fecha: ${record['fecha']}\nTipo: ${record['tipo']}\nMascota ID: ${record['mascotaId']}\n${record['descripcion']}',
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

