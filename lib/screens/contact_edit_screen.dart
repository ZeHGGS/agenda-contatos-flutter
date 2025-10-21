import 'package:flutter/material.dart';
import 'package:teste/models/contact_model.dart';
import 'package:teste/utils/database_helper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';

class ContactEditScreen extends StatefulWidget {
  final Contact? contact;

  const ContactEditScreen({super.key, this.contact});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;
  late bool _isFavorite;

  late TextEditingController _nomeController;
  late TextEditingController _sobrenomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _emailController;
  late TextEditingController _dataNascController;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contact != null;
    _isFavorite = _isEditing ? widget.contact!.isFavorite : false;

    _nomeController = TextEditingController(text: _isEditing ? widget.contact!.nome : '');
    _sobrenomeController = TextEditingController(text: _isEditing ? widget.contact!.sobrenome : '');
    _telefoneController = TextEditingController(text: _isEditing ? widget.contact!.telefone : '');
    _emailController = TextEditingController(text: _isEditing ? widget.contact!.email : '');
    _dataNascController = TextEditingController(text: _isEditing ? widget.contact!.dataNascimento : '');

    _telefoneController.text = _phoneFormatter.maskText(_telefoneController.text);
    _dataNascController.text = _dateFormatter.maskText(_dataNascController.text);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _dataNascController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: _isEditing ? widget.contact!.id : null,
        nome: _nomeController.text,
        sobrenome: _sobrenomeController.text,
        telefone: _phoneFormatter.unmaskText(_telefoneController.text),
        email: _emailController.text,
        dataNascimento: _dataNascController.text,
        isFavorite: _isFavorite,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.update(contact);
      } else {
        await DatabaseHelper.instance.create(contact);
      }

      _showSuccessScreen();
    }
  }

  Future<void> _deleteContact() async {
    if (!_isEditing) return;

    final bool? shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Você tem certeza que quer deletar este contato?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await DatabaseHelper.instance.delete(widget.contact!.id!);
      Navigator.of(context).pop('deleted');
    }
  }

  void _showSuccessScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop('edited');
        });
        
        return const Dialog(
          backgroundColor: Color(0xFFC0A080),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFFFF8F0),
                ),
                SizedBox(height: 20),
                Text(
                  "Contato Salvo!", 
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();
    if (_dataNascController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(_dataNascController.text);
      } catch (e) {
        // Ignora data inválida
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != initialDate) {
      setState(() {
        _dataNascController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    TextInputType keyboardType = TextInputType.text;
    List<MaskTextInputFormatter> inputFormatters = [];
    Widget? suffixIcon = const Icon(Icons.arrow_forward_ios, size: 16);

    if (label == 'Telefone') {
      keyboardType = TextInputType.phone;
      inputFormatters = [_phoneFormatter];
    } else if (label == 'Data de Nascimento') {
      keyboardType = TextInputType.datetime;
      inputFormatters = [_dateFormatter];
      suffixIcon = IconButton(
        icon: const Icon(Icons.calendar_month),
        onPressed: _selectDate,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFDBC8B0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
        validator: (value) {
          if (label == 'Nome' && (value == null || value.isEmpty)) {
            return 'O nome é obrigatório';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Contato' : 'Adicionar Contato'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.brown[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFDBC8B0),
                child: _nomeController.text.isNotEmpty
                    ? Text(
                        _nomeController.text[0].toUpperCase(),
                        style: const TextStyle(fontSize: 48, color: Colors.white),
                      )
                    : const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              _buildTextField('Nome', _nomeController),
              _buildTextField('Sobrenome', _sobrenomeController),
              _buildTextField('Telefone', _telefoneController),
              _buildTextField('E-mail', _emailController),
              _buildTextField('Data de Nascimento', _dataNascController),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveContact,
        backgroundColor: Colors.white,
        foregroundColor: Colors.brown[600],
        child: const Icon(Icons.save),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFF8F0),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.star : Icons.star_outline,
                  color: _isFavorite ? Colors.amber[700] : Colors.grey[700],
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
              ),
              const Spacer(), 
              const Spacer(),
              if (_isEditing)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 30),
                  onPressed: _deleteContact, 
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}