import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/screens/order/widgets/orders_list.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/order_controller.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(OrderController());

  @override
  void initState() {
    super.initState();
    // 5 tabs: Todos, Pendiente/Procesando, Enviando, Entregado, Cancelado
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      /// AppBar
      appBar: TAppBar(
        title: Text(
          'Mis Compras',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: Column(
        children: [
          /// TabBar con contadores dinámicos
          FutureBuilder<List<int>>(
            future: _getTabCounts(),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? [0, 0, 0, 0, 0];

              return Container(
                color: dark ? TColors.dark : TColors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true, // Permite deslizar si no caben
                  tabAlignment: TabAlignment.start,
                  indicatorColor: TColors.primary,
                  labelColor: TColors.primary,
                  unselectedLabelColor: dark ? TColors.darkGrey : TColors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    _buildTab('Todos', counts[0]),
                    _buildTab('Pendiente', counts[1]),
                    _buildTab('Enviando', counts[2]),
                    _buildTab('Entregado', counts[3]),
                    _buildTab('Cancelado', counts[4]),
                  ],
                ),
              );
            },
          ),

          /// TabBarView con contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  TOrderListItems(filterStatus: null), // Todos
                  TOrderListItems(filterStatus: OrderStatus.processing), // Pendiente/Procesando
                  TOrderListItems(filterStatus: OrderStatus.shipped), // Enviando
                  TOrderListItems(filterStatus: OrderStatus.delivered), // Entregado
                  TOrderListItems(filterStatus: OrderStatus.cancelled), // Cancelado
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construir tab con contador
  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Obtener contadores para cada tab
  Future<List<int>> _getTabCounts() async {
    final all = await controller.countOrdersByStatus(null);
    final pending = await controller.countOrdersByStatus(OrderStatus.processing); // Incluye pending
    final shipped = await controller.countOrdersByStatus(OrderStatus.shipped);
    final delivered = await controller.countOrdersByStatus(OrderStatus.delivered);
    final cancelled = await controller.countOrdersByStatus(OrderStatus.cancelled);

    return [all, pending, shipped, delivered, cancelled];
  }
}