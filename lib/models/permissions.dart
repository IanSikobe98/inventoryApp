/// Privilege names the API puts in `usersPerm` after sign-in.
///
/// Hiding a button or tab is only a convenience for the person using the app.
/// The API must still check the same privileges on every request.
class Perm {
  static const viewInventory = 'VIEW_INVENTORY';
  static const createInventory = 'CREATE_INVENTORY';
  static const updateInventory = 'UPDATE_INVENTORY';
  static const createSales = 'CREATE_SALES';
  static const viewSales = 'VIEW_SALES';
  static const viewPayment = 'VIEW_PAYMENT';
  static const createPayment = 'CREATE_PAYMENT';

  /// Every privilege the app knows about (used by tests).
  static const all = {
    viewInventory,
    createInventory,
    updateInventory,
    createSales,
    viewSales,
    viewPayment,
    createPayment,
  };
}
