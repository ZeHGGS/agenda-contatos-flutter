import 'package:flutter/material.dart';
import 'package:teste/models/contact_model.dart';
import 'package:teste/screens/contact_edit_screen.dart';
import 'package:teste/utils/database_helper.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ContactViewScreen extends StatefulWidget {
  final int contactId;

  const ContactViewScreen({super.key, required this.contactId});

  @override
  State<ContactViewScreen> createState() => _ContactViewScreenState();
}

class _ContactViewScreenState extends State<ContactViewScreen> {
  Contact? _contact;
  bool _isLoading = true;
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    setState(() => _isLoading = true);
    final contact = await DatabaseHelper.instance.getContact(widget.contactId);
    setState(() {
      _contact = contact;
      _isLoading = false;
    });
  }

  void _navigateToEditScreen() async {
    if (_contact == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactEditScreen(contact: _contact),
      ),
    );

    if (result == 'deleted') {
      Navigator.of(context).pop(true);
    } else if (result == 'edited') {
      _loadContact();
      _didChange = true;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_contact == null) return;

    final updatedContact = _contact!;
    updatedContact.isFavorite = !updatedContact.isFavorite;

    await DatabaseHelper.instance.update(updatedContact);
    
    setState(() {
      _contact = updatedContact;
    });
    _didChange = true;
  }

  Future<void> _deleteContact() async {
    if (_contact == null) return;

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
      await DatabaseHelper.instance.delete(_contact!.id!);
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildInfoRow(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    if (label == 'Telefone') {
      try {
        final formatter = MaskTextInputFormatter(
          mask: '(##) #####-####',
          filter: {"#": RegExp(r'[0-9]')},
        );
        value = formatter.maskText(value);
      } catch (e) {
        // ignora se falhar
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 16),
          Expanded( 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value!, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didChange);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          title: const Text('Detalhes do Contato'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.brown[700],
          actions: [
            if (_contact != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _navigateToEditScreen,
              ),
          ],
        ),
        body: _isLoading || _contact == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFDBC8B0),
                      child: _contact!.nome.isNotEmpty
                          ? Text(
                              _contact!.nome[0].toUpperCase(),
                              style: const TextStyle(fontSize: 48, color: Colors.white),
                            )
                          : const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_contact!.nome} ${_contact!.sobrenome ?? ''}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    _buildInfoRow('Telefone', _contact!.telefone, Icons.phone),
                    _buildInfoRow('E-mail', _contact!.email, Icons.email),
                    _buildInfoRow('Data de Nascimento', _contact!.dataNascimento, Icons.calendar_month),
                  ],
                ),
              ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFFFFF8F0),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    _contact?.isFavorite == true ? Icons.star : Icons.star_outline,
                    color: _contact?.isFavorite == true ? Colors.amber[700] : Colors.grey[700],
                    size: 30,
                  ),
                  onPressed: _isLoading ? null : _toggleFavorite,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[700], size: 30),
                  onPressed: _isLoading ? null : _deleteContact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}