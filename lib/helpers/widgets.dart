import 'dart:io';

import 'package:flutter/material.dart';
import 'package:itrek/helpers/img.dart';

/// Un widget reutilizable para crear botones circulares con un ícono.
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color; // Color del fondo
  final Color? iconColor; // Color del ícono (opcional)
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final double opacity;

  const CircleIconButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.iconColor,
    this.size = 60,
    this.iconSize = 30,
    this.opacity = 0.1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor ?? color,
          size: iconSize,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Un widget reutilizable para campos de texto en formularios.
class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const ProfileTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      enabled: enabled,
    );
  }
}

/// Un widget para mostrar la imagen de perfil con un botón de edición.
Widget buildProfileImage({
  required String imageUrl,
  required File? imageFile,
  required VoidCallback onEdit,
  required bool editMode,
}) {
  return Stack(
    alignment: Alignment.bottomRight,
    children: [
      CircleAvatar(
        radius: 60,
        backgroundImage: (imageFile != null)
            ? FileImage(imageFile)
            : (imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : const AssetImage('assets/images/profile.png')) as ImageProvider,
      ),
      if (editMode)
        CircleIconButton(
          icon: Icons.camera_alt,
          color: Colors.blue.shade100,
          iconColor: Colors.blue.shade800,
          onPressed: onEdit,
          size: 50,
          iconSize: 24,
          opacity: 0.8,
        ),
    ],
  );
}

class DashboardButton extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onPressed;

  const DashboardButton({
    Key? key,
    required this.label,
    required this.imagePath,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF50C9B5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Image.asset(
            imagePath,
            height: 80,
          ),
        ],
      ),
    );
  }
}

class DashboardCircleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;

  const DashboardCircleButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 50,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un widget que oculta su contenido cuando el teclado está visible.
class KeyboardAwareFooter extends StatelessWidget {
  final List<Widget> children;

  const KeyboardAwareFooter({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detecta si el teclado está visible
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Visibility(
      visible: !isKeyboardVisible, // Muestra u oculta según el estado del teclado
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.white.withOpacity(0.9), // Fondo blanco semitransparente
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }
}

/// Un widget que fija su contenido en la parte inferior de la pantalla.
/// Oculta automáticamente el contenido cuando el teclado está visible.
class FixedFooter extends StatelessWidget {
  final List<Widget> children;

  const FixedFooter({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Detecta si el teclado está visible
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isKeyboardVisible ? 0 : 70, // Oculta el footer si el teclado está activo
        color: Colors.white.withOpacity(0.9), // Fondo blanco semitransparente
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool withLogo;
  final Color backgroundColor;
  final Color iconColor;
  final TextStyle? titleStyle;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.withLogo = true,
    this.backgroundColor = const Color(0xFF338855),
    this.iconColor = Colors.white,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
          children: [
            if (withLogo) logoWhite,
            if (withLogo) const SizedBox(width: 10),
            Text(
              title,
              style: titleStyle ??
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
            ),
          ],
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A reusable custom text field widget for forms.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final TextInputType keyboardType;
  final String? errorText;
  final String? Function(String?)? validator;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
        errorText: errorText,
      ),
    );
  }
}
