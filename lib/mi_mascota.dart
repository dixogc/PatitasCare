import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PerfilMascotaPage extends StatefulWidget {
  @override
  _PerfilMascotaPageState createState() => _PerfilMascotaPageState();
}

class _PerfilMascotaPageState extends State<PerfilMascotaPage> {
  // Datos de ejemplo (puedes cargar estos datos desde backend)
  String nombre = 'Firulais';
  String especie = 'Perro';
  String raza = 'Labrador';
  String color = 'Marrón';

  String edad = '3';
  String peso = '20';
  String tamano = 'Grande';

  File? _imagenMascota;

  final picker = ImagePicker();

  Future<void> _seleccionarImagen() async {
    final imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagenMascota = File(imagen.path);
      });
    }
  }

  void _editarCampo(
    String campo,
    String valorActual,
    Function(String) onGuardar,
  ) {
    TextEditingController controller = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar $campo'),
        content: TextField(
          controller: controller,
          keyboardType: campo == 'Edad' || campo == 'Peso'
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(hintText: 'Ingresa nuevo valor'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onGuardar(controller.text);
              Navigator.pop(context);
            },
            child: Text('Guardar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _dato(
    String label,
    String valor, {
    bool editable = false,
    Function()? onTap,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(valor),
      trailing: editable ? Icon(Icons.edit, color: Colors.blue) : null,
      onTap: editable ? onTap : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Perfil de Mascota')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _seleccionarImagen,
              child: CircleAvatar(
                radius: 70,
                backgroundImage: _imagenMascota != null
                    ? FileImage(_imagenMascota!)
                    : AssetImage('assets/placeholder_pet.png') as ImageProvider,
                child: _imagenMascota == null
                    ? Icon(Icons.add_a_photo, size: 30, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            _dato('Nombre', nombre),
            _dato('Especie', especie),
            _dato('Raza', raza),
            _dato('Color', color),
            Divider(),
            _dato(
              'Edad',
              edad,
              editable: true,
              onTap: () {
                _editarCampo('Edad', edad, (nuevo) {
                  setState(() {
                    edad = nuevo;
                  });
                });
              },
            ),
            _dato(
              'Peso (kg)',
              peso,
              editable: true,
              onTap: () {
                _editarCampo('Peso', peso, (nuevo) {
                  setState(() {
                    peso = nuevo;
                  });
                });
              },
            ),
            _dato(
              'Tamaño',
              tamano,
              editable: true,
              onTap: () {
                _editarCampo('Tamaño', tamano, (nuevo) {
                  setState(() {
                    tamano = nuevo;
                  });
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
