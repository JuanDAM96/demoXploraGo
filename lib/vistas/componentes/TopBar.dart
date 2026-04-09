import 'package:flutter/material.dart';
import 'package:xplorago/nucleo/temas/colores_tema.dart';
import 'package:xplorago/nucleo/temas/tipografia_tema.dart';

class TopBarMenuItem {
	const TopBarMenuItem({
		required this.label,
		this.onTap,
		this.icon,
	});

	final String label;
	final IconData? icon;
	final VoidCallback? onTap;
}

class TopBar extends StatelessWidget implements PreferredSizeWidget {
	const TopBar({
		super.key,
		this.title = 'XploraGo',
		this.menuLabel = 'menu ext...',
		this.leading,
		this.subtitle,
		this.menuItems = const <TopBarMenuItem>[],
		this.backgroundColor,
		this.foregroundColor,
		this.menuBackgroundColor,
		this.menuTextColor,
		this.onMenuPressed,
	});

	final String title;
	final String menuLabel;
	final String? subtitle;
	final Widget? leading;
	final List<TopBarMenuItem> menuItems;
	final Color? backgroundColor;
	final Color? foregroundColor;
	final Color? menuBackgroundColor;
	final Color? menuTextColor;
	final VoidCallback? onMenuPressed;

	@override
	Size get preferredSize => const Size.fromHeight(96);

	@override
	Widget build(BuildContext context) {
		final Color resolvedBackgroundColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
		final Color resolvedForegroundColor = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;
		final Color resolvedMenuBackgroundColor = menuBackgroundColor ?? Theme.of(context).colorScheme.primary;
		final Color resolvedMenuTextColor = menuTextColor ?? Theme.of(context).colorScheme.onPrimary;

		return Material(
			color: resolvedBackgroundColor,
			elevation: 0,
			child: SafeArea(
				bottom: false,
				child: SizedBox(
					height: preferredSize.height,
					child: Stack(
						children: [
							Padding(
								padding: const EdgeInsets.only(left: 14, right: 12, top: 10),
								child: Row(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										leading ??
											Container(
												width: 58,
												height: 58,
												decoration: BoxDecoration(
													color: AppColors.negro.withValues(alpha: 0.16),
													shape: BoxShape.circle,
													border: Border.all(color: AppColors.negro, width: 1.6),
												),
												child: Icon(
													Icons.explore,
													color: resolvedForegroundColor,
													size: 30,
												),
											),
										const SizedBox(width: 12),
										Expanded(
											child: Padding(
												padding: const EdgeInsets.only(top: 18),
												child: Text(
													title,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
													style: AppTextStyles.boton(color: resolvedForegroundColor).copyWith(
														fontSize: 18,
														fontStyle: FontStyle.italic,
													),
												),
											),
										),
									],
								),
							),
							Align(
								alignment: Alignment.topRight,
								child: Padding(
									padding: const EdgeInsets.only(top: 8, right: 12),
									child: _TopBarMenuButton(
										menuLabel: menuLabel,
										menuItems: menuItems,
										foregroundColor: resolvedForegroundColor,
										menuBackgroundColor: resolvedMenuBackgroundColor,
										menuTextColor: resolvedMenuTextColor,
										onMenuPressed: onMenuPressed,
									),
								),
							),
						],
					),
				),
			),
		);
	}
}

class _TopBarMenuButton extends StatelessWidget {
	const _TopBarMenuButton({
		required this.menuLabel,
		required this.menuItems,
		required this.foregroundColor,
		required this.menuBackgroundColor,
		required this.menuTextColor,
		this.onMenuPressed,
	});

	final String menuLabel;
	final List<TopBarMenuItem> menuItems;
	final Color foregroundColor;
	final Color menuBackgroundColor;
	final Color menuTextColor;
	final VoidCallback? onMenuPressed;

	@override
	Widget build(BuildContext context) {
		if (menuItems.isNotEmpty) {
			return PopupMenuButton<int>(
				padding: EdgeInsets.zero,
				color: menuBackgroundColor,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(14),
				),
				offset: const Offset(0, 8),
				icon: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.end,
					children: [
						Text(
							menuLabel,
							style: AppTextStyles.etiqueta(color: Theme.of(context).colorScheme.primary).copyWith(
								fontSize: 12,
							),
						),
						const SizedBox(height: 4),
						Icon(Icons.menu, color: foregroundColor, size: 28),
					],
				),
				onSelected: (int index) {
					menuItems[index].onTap?.call();
				},
				itemBuilder: (BuildContext context) {
					return List<PopupMenuEntry<int>>.generate(menuItems.length, (int index) {
						final TopBarMenuItem item = menuItems[index];
						return PopupMenuItem<int>(
							value: index,
							child: SizedBox(
								width: 120,
								child: Center(
									child: Text(
										item.label,
										style: AppTextStyles.etiqueta(color: menuTextColor).copyWith(
											fontSize: 13,
										),
									),
								),
							),
						);
					});
				},
			);
		}

		return TextButton.icon(
			onPressed: onMenuPressed,
			icon: Icon(Icons.menu, color: foregroundColor, size: 28),
			label: Text(
				menuLabel,
				style: AppTextStyles.etiqueta(color: Theme.of(context).colorScheme.primary).copyWith(fontSize: 12),
			),
		);
	}
}
