import 'package:tienda_ropa/features/shop/models/category_model.dart';
import 'package:tienda_ropa/features/shop/models/product_attribute_model.dart';
import 'package:tienda_ropa/features/shop/models/product_variation_model.dart';

import '../../../features/shop/models/banner_model.dart';
import '../../../features/shop/models/brand_model.dart';
import '../../../features/shop/models/product_model.dart';
import '../../../routes/routes.dart';
import '../../../utils/constants/image_strings.dart';

class TDummyData {
  /// -- Banners
  static final List<BannerModel> banners = [
    BannerModel(imageUrl: TImages.promoBanner1, targetScreen: TRoutes.order, active: false),
    BannerModel(imageUrl: TImages.promoBanner2, targetScreen: TRoutes.cart, active: true),
    BannerModel(imageUrl: TImages.promoBanner3, targetScreen: TRoutes.favourites, active: true),
    BannerModel(imageUrl: TImages.promoBanner4, targetScreen: TRoutes.search, active: true),
    BannerModel(imageUrl: TImages.promoBanner5, targetScreen: TRoutes.settings, active: true),
    BannerModel(imageUrl: TImages.promoBanner6, targetScreen: TRoutes.userAddress, active: true),
    BannerModel(imageUrl: TImages.promoBanner8, targetScreen: TRoutes.checkout, active: false),
  ];

  /// -- Usuario
  /// -- Orden
  /// -- Lista de todas las categorias
  static final List<CategoryModel> categories = [
    CategoryModel(id: '1', image: TImages.sportIcon, name: 'Deportes', isFeatured: true),
    CategoryModel(id: '2', image: TImages.furnitureIcon, name: 'Muebles', isFeatured: true),
    CategoryModel(id: '3', image: TImages.electronicsIcon, name: 'Electronica', isFeatured: true),
    CategoryModel(id: '4', image: TImages.clothIcon, name: 'Ropa', isFeatured: true),
    CategoryModel(id: '5', image: TImages.animalIcon, name: 'Mascotas', isFeatured: true),
    CategoryModel(id: '6', image: TImages.shoeIcon, name: 'Zapatos', isFeatured: true),
    CategoryModel(id: '8', image: TImages.cosmeticsIcon, name: 'Cosmeticos', isFeatured: true),
    CategoryModel(id: '9', image: TImages.jeweleryIcon, name: 'Joyeria', isFeatured: true),

    /// -- Sub Categorias
    CategoryModel(id: '10', image: TImages.sportIcon, name: 'Zapatos Deportivos', parentId: '1', isFeatured: false),
    CategoryModel(id: '11', image: TImages.sportIcon, name: 'Zapatos Formales', parentId: '1', isFeatured: false),
    CategoryModel(id: '12', image: TImages.sportIcon, name: 'Equipamento Deportivo', parentId: '1', isFeatured: false),
    // Muebles
    CategoryModel(id: '13', image: TImages.furnitureIcon, name: 'Muebles para Dormitorio', parentId: '5', isFeatured: false),
    CategoryModel(id: '14', image: TImages.furnitureIcon, name: 'Muebles para Cocina', parentId: '5', isFeatured: false),
    CategoryModel(id: '15', image: TImages.furnitureIcon, name: 'Muebles de Oficina', parentId: '5', isFeatured: false),
    // Electronica
    CategoryModel(id: '16', image: TImages.electronicsIcon, name: 'Laptop', parentId: '2', isFeatured: false),
    CategoryModel(id: '17', image: TImages.electronicsIcon, name: 'Celulares', parentId: '2', isFeatured: false),
    // Ropa
    CategoryModel(id: '18', image: TImages.clothIcon, name: 'Camisetas', parentId: '3', isFeatured: false),
    CategoryModel(id: '18', image: TImages.clothIcon, name: 'Pantalones', parentId: '3', isFeatured: false),
    CategoryModel(id: '18', image: TImages.clothIcon, name: 'Abrigos', parentId: '3', isFeatured: false),
    CategoryModel(id: '18', image: TImages.clothIcon, name: 'Gorras', parentId: '3', isFeatured: false),
    CategoryModel(id: '18', image: TImages.clothIcon, name: 'Accesorios', parentId: '3', isFeatured: false),
  ];

  /// -- Lista de todas las Marcas
  static final List<BrandModel> brands = [
    BrandModel(id: '1', image: TImages.nikeIcon, name: 'Nike', productsCount: 256, isFeatured: true),
    BrandModel(id: '2', image: TImages.adidasIcon, name: 'Adidas', productsCount: 95, isFeatured: true),
    BrandModel(id: '3', image: TImages.pumaIcon, name: 'Puma', productsCount: 36, isFeatured: true),
    BrandModel(id: '4', image: TImages.reebokIcon, name: 'Reebok', productsCount: 16, isFeatured: true),
  ];

  /// -- Lista de todos los productos
  static final List<ProductModel> products = [
    ProductModel(
      id: '001',
      title: 'Green Nike sports shoes',
      stock: 15,
      price: 135,
      isFeatured: true,
      thumbnail: TImages.productImage1,
      description: 'Green Nike sports shoes',
      brand: BrandModel(id: '1', image: TImages.nikeIcon, name: 'Nike', productsCount: 256, isFeatured: true),
      images: [TImages.productImage1, TImages.productImage2, TImages.productImage3],
      salePrice: 30,
      sku: 'ABR4568',
      categoryId: '1',
      productAttributes: [
        ProductAttributeModel(name: 'Color', values: ['Green', 'Black', 'Red']),
        ProductAttributeModel(name: 'Size', values: ['5.5 US', '6 US', '6.5 US', '7 US']),
      ],
      productVariations: [
        ProductVariationModel(
          id: '1',
          stock: 34,
          price: 134,
          salePrice: 122.6,
          image: TImages.productImage1,
          description: 'Esta es una descripcion de un producto.',
          attributeValues: {'Color': 'Green', 'Size': '5.5 US'}),
        ProductVariationModel(
          id: '2',
          stock: 15,
          price: 132,
          image: TImages.productImage5,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '3',
          stock: 48,
          price: 432,
          image: TImages.productImage8,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '4',
          stock: 2,
          price: 20,
          image: TImages.productImage20,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '5',
          stock: 9,
          price: 25,
          image: TImages.productImage25,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '6',
          stock: 18,
          price: 130,
          image: TImages.productImage4,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
      ],
      productType: 'ProductType.variable',
    ),
    ProductModel(
      id: '002',
      title: 'Red Nike sports shoes',
      stock: 116,
      price: 125,
      isFeatured: false,
      thumbnail: TImages.productImage54,
      description: 'Esta es otra descripcion de un producto',
      brand: BrandModel(id: '2', image: TImages.adidasIcon, name: 'Nike', productsCount: 180, isFeatured: true),
      images: [TImages.productImage4, TImages.productImage5, TImages.productImage6],
      salePrice: 30,
      sku: 'ABR4568',
      categoryId: '17',
      productAttributes: [
        ProductAttributeModel(name: 'Color', values: ['Green', 'Black', 'Red']),
        ProductAttributeModel(name: 'Size', values: ['5.5 US', '6 US', '6.5 US', '7 US']),
      ],
      productVariations: [
        ProductVariationModel(
          id: '1',
          stock: 34,
          price: 134,
          salePrice: 122.6,
          image: TImages.productImage1,
          description: 'Esta es una descripcion de un producto.',
          attributeValues: {'Color': 'Green', 'Size': '5.5 US'}),
        ProductVariationModel(
          id: '2',
          stock: 15,
          price: 132,
          image: TImages.productImage5,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '3',
          stock: 48,
          price: 432,
          image: TImages.productImage8,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '4',
          stock: 2,
          price: 20,
          image: TImages.productImage20,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '5',
          stock: 9,
          price: 25,
          image: TImages.productImage25,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
        ProductVariationModel(
          id: '6',
          stock: 18,
          price: 130,
          image: TImages.productImage4,
          attributeValues: {'Color': 'Black', 'Size': '6 US'},
        ),
      ],
      productType: 'ProductType.variable',
    )
  ];

}