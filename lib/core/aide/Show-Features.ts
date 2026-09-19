
// import {
//   ButtonDirective,
//   ButtonGroupComponent,
//   ButtonToolbarComponent,
//   CardBodyComponent,
//   CardComponent,
//   CardHeaderComponent,
//   ColComponent,
//   DropdownComponent,
//   DropdownDividerDirective,
//   DropdownItemDirective,
//   DropdownMenuDirective,
//   DropdownToggleDirective,
//   FormCheckLabelDirective,
//   FormControlDirective,
//   InputGroupComponent,
//   InputGroupTextDirective,
//   ModalModule,
//   RowComponent,
//   ProgressComponent,
//   ToastBodyComponent,
//   ToastComponent,
//   ToasterComponent,
//   ToastHeaderComponent
// } from '@coreui/angular';
// import { HttpConnectService } from '../../../Services/http-connect.service';
// import { CommonModule } from '@angular/common';
// import { IconModule } from '@coreui/icons-angular';
// import { ServiceModel } from '../../../Models/ServiceModel';
// import { GlobalOrder, GlobalOrderDetail } from '../../../Models/GlobalOrder';
// import { BusinessModel } from '../../../Models/Business/BusinessModel';
// interface OrderStatusOption {
//   orderStatusId: number;
//   statusEn: string;
//   statusAr?: string;
// }
// @Component({
//   selector: 'app-button-groups',
//   templateUrl: './Show-Features.html',
//   imports: [RowComponent, ColComponent, CardComponent, IconModule, ModalModule,
//     CardHeaderComponent, CardBodyComponent, ButtonGroupComponent,
//     ButtonDirective, RouterLink, ReactiveFormsModule,
//     FormCheckLabelDirective, ButtonToolbarComponent,
//     InputGroupComponent, InputGroupTextDirective, RouterLink, RouterOutlet,
//     FormControlDirective, DropdownComponent, FormsModule, CommonModule,
//     DropdownToggleDirective, DropdownMenuDirective,
//     DropdownItemDirective, DropdownDividerDirective,
//     ButtonDirective,
//     ProgressComponent,
//     ToasterComponent,
//     ToastComponent,
//     ToastHeaderComponent,
//     ToastBodyComponent]
// })
// export class ShowFeaturesComponent implements OnInit {

//   orders: GlobalOrder[] = [];
//   allOrders: GlobalOrder[] = [];
//   message?: string;
//   isLoading: boolean = false;
//   showDeleteModal: boolean = false;
//   selectedOrder?: GlobalOrder;
//   myTasksOnly: boolean | null = null;

//   position = 'top-end';
//   toastVisible = signal(false);
//   toastMessage = signal('');
//   percentage = signal(0);
//   autoHideToast = signal(true);

//   notes: string = '';
//   statusEn: string = '';
//   BusinessId?: number;
//   ServiceId?: number;
//   loading: boolean = false;
//   comment: string = '';
//   selectedOrderId?: number;
//   comments: any[] = [];
//   Businesses?: BusinessModel[];
//   Services?: ServiceModel[];
//   selectedFilter: string = 'All';
//   allCountOfTasks: number = 0;
//   myName: string = '';

//   showEditModal = false;

//   completedCount = 0;
//   progressCount = 0;
//   newCount = 0;

//   constructor(private http: HttpConnectService, private cdr: ChangeDetectorRef) { }

//   ngOnInit(): void {
//     // this.getAllOrders();  <-- اتشال، مفيش تحميل تلقائي أول ما الصفحة تفتح
//     this.getAllBusiness();
//     const currentUser = JSON.parse(localStorage.getItem('currentUser') || '{}');
//     this.myName = currentUser.userName ?? '';
//   }

//   // -------- دالة جديدة: بتتنادى من زرار الـ toggle --------
//   selectTaskView(mine: boolean) {
//     this.myTasksOnly = mine;
//     // TODO: لما تتحدد الـ API المخصصة لـ "My Tasks" (فلترة server-side
//     // حسب الـ assignee)، نستبدل النداء ده بيها. حاليًا placeholder بيستخدم
//     // نفس getAllOrders الموجودة.
//     this.getOrderStatuses()
//     this.getAllOrders();

//   }

//   getAllBusiness() {
//     const businessId = localStorage.getItem('businessId');
//     this.http.getAllData(`Business/GetAllBusinessForTask/${businessId}`).subscribe(res => {
//       this.Businesses = (res as BusinessModel[]).map((el) => new BusinessModel({
//         business_id: el.business_id,
//         business_name: el.business_name
//       }));
//       this.getAllServices();
//     }, (error) => {
//       console.error(error);
//       this.loading = false;
//     });
//   }


//   OrderStatuses?: OrderStatusOption[];
//   selectedOrderStatusId?: number;

//   getOrderStatuses() {
//     const serviceId = Number(localStorage.getItem('selectedServiceId'));
//     this.http.getAllData(`UniversalOrder/GetAllOrderStatusByService/${serviceId}`).subscribe((res: any) => {
//       this.OrderStatuses = res as OrderStatusOption[];
      
//     }, (error) => {
//       console.error(error);
//     });
//   }

//   getAllServices() {
//     const businessId = Number(localStorage.getItem('businessId'));

//     this.http.getAllData(`Service/${businessId}`).subscribe(res => {
//       this.Services = (res as ServiceModel[])
//         .filter(el =>
//           el.business_Services?.some((bs: any) => bs.business_id === businessId)
//         )
//         .map(el => new ServiceModel({
//           service_id: el.service_id,
//           description: el.description
//         }));
//       this.cdr.detectChanges();
//     }, error => {
//       console.error(error);
//       this.loading = false;
//     });
//   }

//   getAllOrders() {
//     this.isLoading = true;
//     const businessId = localStorage.getItem('businessId');
//     const serviceId = localStorage.getItem('selectedServiceId');
//     this.http.getAllData(`Orders/${businessId}/${serviceId}`).subscribe(
//       (res: any) => {
//         console.log(res)
//         this.orders = (res as any[]).map(item => new GlobalOrder(item));
//         this.allCountOfTasks = this.orders.length;
//         this.allOrders = this.orders;
//         this.calculateStats();
//         this.isLoading = false;
//         this.cdr.detectChanges();
//       },
//       (err) => {
//         this.isLoading = false;
//         this.message = 'Error loading data';
//         this.cdr.detectChanges();
//       }
//     );
//   }

//   calculateStats() {
//     this.orders = this.orders.filter(x => x.orderStatus?.statusEn !== 'Closed');
//     this.completedCount =
//       this.orders.filter(x => x.orderStatus?.statusEn === 'Completed').length;

//     this.progressCount =
//       this.orders.filter(x => x.orderStatus?.statusEn === 'On progress').length;

//     this.newCount =
//       this.orders.filter(x => x.orderStatus?.statusEn === 'New').length;

//     this.filterTasks(this.selectedFilter);
//   }

//   confirmDelete(order: GlobalOrder) {
//     this.selectedOrder = order;
//     this.showDeleteModal = true;
//   }

//   deleteOrder(order?: GlobalOrder) {
//     if (!order) return;
//     this.http.deleteData(`Orders/${order.globalOrderId}`).subscribe(() => {
//       this.orders = this.orders.filter(o => o.globalOrderId !== order.globalOrderId);
//       this.showDeleteModal = false;
//       this.toastMessage.set(`Order #${order.globalOrderId} deleted successfully`);
//       this.toastVisible.set(true);
//     }, (error) => {
//       this.toastMessage.set(`An error occurred during delete (#${order.globalOrderId})`);
//       this.toastVisible.set(true);
//     });
//   }

//   onVisibleChange(visible: boolean) {
//     this.showDeleteModal = false;
//     this.toastVisible.set(visible);
//     if (!visible) this.percentage.set(0);
//   }

//   onTimerChange(value: number) {
//     this.percentage.set(value * 25);
//   }

//   openEditModal(order: GlobalOrder) {
//     this.showEditModal = true;
//     this.notes = order.notes || '';
//     this.comments = order.comments ? order.comments : [];
//     this.statusEn = order.orderStatus?.statusEn || '';
//     this.selectedOrderId = order.globalOrderId;
//     this.selectedOrder = order;
//     this.BusinessId = order.business_id;
//     this.ServiceId = order.service_id || undefined;
//     this.selectedOrderStatusId = order.orderStatus?.orderStatusId || undefined;
//     this.makeAllCommentsRead(this.selectedOrderId!);
//   }

//   addComment() {
//     if (!this.comment.trim()) {
//       this.toastMessage.set('Comment cannot be empty');
//       this.toastVisible.set(true);
//       return;
//     }
//     this.http.putData(`Orders/AddComment/${this.selectedOrderId}`, { comment: this.comment }).subscribe(
//       () => {
//         this.comments.push({
//           addedBy: this.myName,
//           commentContent: this.comment,
//           addedOn: Date.now()
//         });
//         this.cdr.detectChanges();
//         this.getAllOrders();
//         this.comment = '';
//         this.toastMessage.set('Comment added successfully');
//         this.toastVisible.set(true);
//       },
//       (error) => {
//         console.error('Error adding comment:', error);
//         this.toastMessage.set('An error occurred while adding the comment');
//         this.toastVisible.set(true);
//       }
//     );
//   }

//   updateOrder(orderId: number) {
//     const updatedOrder = {
//       notes: this.notes,
//       statusId: this.selectedOrderStatusId,
//     };

//     this.http.putData(`Orders/UpdateETaskOrder/${orderId}`, updatedOrder).subscribe(
//       () => {
//         this.toastMessage.set('Order updated successfully');
//         this.toastVisible.set(true);
//         this.getAllOrders();
//         this.showEditModal = false;
//       },
//       (error) => {
//         console.error('Error updating order:', error);
//         this.toastMessage.set('An error occurred while updating the order');
//         this.toastVisible.set(true);
//       }
//     );
//   }

//   SetStatusClosed(id: number) {
//     this.http.putData(`Orders/SetTaskStatusClosed/${id}`, {}).subscribe(
//       () => {
//         this.toastMessage.set('Order updated successfully');
//         this.toastVisible.set(true);
//         this.getAllOrders();
//         this.showEditModal = false;
//       },
//       (error) => {
//         this.toastMessage.set('An error occurred while updating the order');
//         this.toastVisible.set(true);
//       }
//     );
//   }

//   SetStatusCompleted(id: number) {
//     this.http.putData(`Orders/SetStatusCompleted/${id}`, {}).subscribe(
//       () => {
//         this.toastMessage.set('Order updated successfully');
//         this.toastVisible.set(true);
//         this.getAllOrders();
//         this.showEditModal = false;
//       },
//       (error) => {
//         this.toastMessage.set('An error occurred while updating the order');
//         this.toastVisible.set(true);
//       }
//     );
//   }

//   filterTasks(filter: string) {
//     this.orders = this.allOrders;
//     if (filter === 'All') {
//       this.orders = this.orders.filter(x => x.orderStatus?.statusEn !== 'Closed');
//       return;
//     }
//     this.orders = this.orders.filter(x => x.orderStatus?.statusEn === filter.trim());
//   }

//   getUnReadComments(commentss?: any[] | null): number {
//     if (!commentss) return 0;
//     return commentss.filter(c => !c.isRead).length;
//   }

//   makeAllCommentsRead(orderId: number) {
//     this.http.putData(`Orders/makeAllCommentsRead/${orderId}`, {}).subscribe(() => { });
//   }

//   closeModal() {
//     this.showEditModal = false;
//     this.getAllOrders();
//     this.cdr.detectChanges();
//   }

//   getDetailStatusColor(detail: GlobalOrderDetail): string {
//     switch (detail.orderStatus?.statusEn?.toLowerCase()?.trim()) {
//       case 'pending': return 'warning';
//       case 'confirmed':
//       case 'on progress': return 'info';
//       case 'completed': return 'success';
//       case 'cancelled':
//       case 'closed': return 'danger';
//       default: return 'secondary';
//     }
//   }
// }


