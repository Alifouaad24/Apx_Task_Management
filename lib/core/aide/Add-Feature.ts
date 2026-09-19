// import { CommonModule } from '@angular/common';
// import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
// import { FormsModule } from '@angular/forms';
// import { Router, RouterLink, RouterOutlet } from '@angular/router';
// import { ButtonDirective, CardBodyComponent, CardComponent, CardHeaderComponent, ColComponent, RowComponent } from '@coreui/angular';
// import { IconDirective } from '@coreui/icons-angular';
// import { HttpConnectService } from '../../../Services/http-connect.service';
// import { ServiceModel } from '../../../Models/ServiceModel';
// import { BusinessModel } from '../../../Models/Business/BusinessModel';

// interface OrderStatusOption {
//   orderStatusId: number;
//   statusEn: string;
//   statusAr?: string;
// }

// interface CustomerOption {
//   globalCustomerId: number;
//   customerName: string;
// }

// // شكل موحّد نضع فيه أي قائمة (بزنس/كستمر/سستم) بعد التحويل
// interface AssignOption {
//   id: number | string;
//   name: string;
// }

// @Component({
//   selector: 'app-buttons',
//   templateUrl: './Add-Feature.html',
//   imports: [RowComponent, ColComponent,
//     CardComponent, CardHeaderComponent,
//     CardBodyComponent, CommonModule, FormsModule, RouterOutlet,
//     ButtonDirective, IconDirective, RouterLink,
//   ]
// })
// export class AddEditFeatureComponent implements OnInit {
//   notes: string = '';
//   message: string = '';
//   loading: boolean = false;

//   Businesses?: BusinessModel[];
//   Services?: ServiceModel[];
//   OrderStatuses?: OrderStatusOption[];
//   Customers?: CustomerOption[];
//   assignTypes: any[] = [];

//   selectedServiceId?: number;
//   selectedBusinessId?: number;
//   selectedOrderStatusId?: number;
//   selectedCustomerId?: number;

//   scheduleDate: string = '';
//   scheduleTime: string = '';

//   selectedAssigneeTypeId?: number;
//   selectedAssignerTypeId?: number;
//   selectedAssignerId?: number | string;
//   selectedAssigneeId?: number | string;

//   // القوائم اللي راح تظهر بالـ select الثاني (تتغير حسب النوع المختار)
//   assignerOptions: AssignOption[] = [];
//   assigneeOptions: AssignOption[] = [];

//   loadingServices = false;
//   loadingAssignerOptions = false;
//   loadingAssigneeOptions = false;

//   constructor(private http: HttpConnectService, private router: Router, private cdr: ChangeDetectorRef) { }

//   ngOnInit(): void {
//     this.getAllBusiness();
//     this.getOrderStatuses();
//     this.getAllCustomers();
//     this.getAllAssignTypes();
//   }

//   getAllAssignTypes() {
//     this.http.getAllData('Orders/GetAllAssignTypes').subscribe((res: any) => {
//       this.assignTypes = res;
//       console.log(this.assignTypes)

//       this.onAssignerTypeChange(4)
//       setTimeout(() => {}, 500)
//       this.onAssigneeTypeChange(4)
//       this.cdr.detectChanges()
//     });
//   }

//   getAllBusiness() {
//     const businessId = localStorage.getItem('businessId');

//     this.http.getAllData(`Business/GetAllBusinessForTask/${businessId}`).subscribe(res => {
//       this.Businesses = (res as BusinessModel[]).map((el) => new BusinessModel({
//         business_id: el.business_id,
//         business_name: el.business_name
//       }));

//       this.selectedBusinessId = this.Businesses.find(el => el.business_id == Number(businessId))?.business_id;

//       if (this.selectedBusinessId) {
//         this.getAllServices(this.selectedBusinessId);
//       }

//       this.cdr.detectChanges();
//     }, (error) => {
//       console.error(error);
//       this.loading = false;
//     });
//   }

//   getAllServices(businessId: number | undefined) {
//     if (!businessId) {
//       this.Services = [];
//       return;
//     }
//     this.loadingServices = true;
//     this.Services = [];
//     this.http.getAllData(`Service/${businessId}`).subscribe(res => {
//       this.Services = (res as ServiceModel[]).map((el) => new ServiceModel({
//         service_id: el.service_id,
//         description: el.description
//       }));
//       this.loadingServices = false;
//       this.selectedServiceId = Number(localStorage.getItem('selectedServiceId'));
//       this.cdr.detectChanges();
//     }, (error) => {
//       console.error(error);
//       this.loading = false;
//       this.loadingServices = false;
//     });
//   }

//   getOrderStatuses() {
//     const serviceId = Number(localStorage.getItem('selectedServiceId'));
//     this.http.getAllData(`UniversalOrder/GetAllOrderStatusByService/${serviceId}`).subscribe((res: any) => {
//       this.OrderStatuses = res as OrderStatusOption[];
//       this.selectedOrderStatusId = this.OrderStatuses.filter((el) => el.statusEn.includes('New'))[0].orderStatusId
//     }, (error) => {
//       console.error(error);
//     });
//   }

//   getAllCustomers() {
//     const businessIdForTask = localStorage.getItem('businessId');
//     this.http.getAllData(`Customers/${businessIdForTask}`).subscribe((res: any) => {
//       this.Customers = res as CustomerOption[];
//     }, (error) => {
//       console.error(error);
//     });
//   }

//   // =======================================================================
//   // هذا هو قلب المنطق اللي سألت عنه: يجيب القائمة الصحيحة حسب النوع المختار
//   // =======================================================================
//   private loadOptionsForType(
//     typeName: string,
//     onLoading: (state: boolean) => void,
//     onResult: (options: AssignOption[]) => void
//   ) {
//     onLoading(true);

//     switch (typeName) {
//       case 'Business': {
//         const businessIdForTask = localStorage.getItem('businessId');
//         this.http.getAllData(`Business/GetAllBusinessForTask/${businessIdForTask}`).subscribe({
//           next: (res: any) => {
//             // ✅ Business_id و Business_name → نحولها لـ { id, name }
//             const options: AssignOption[] = (res as any[]).map(b => ({
//               id: String(b.business_id ?? b.Business_id),
//               name: b.business_name ?? b.Business_name,
//             }));
//             onResult(options);
//             onLoading(false);
//           },
//           error: (err) => {
//             console.error(err);
//             onResult([]);
//             onLoading(false);
//           },
//         });
//         break;
//       }

//       case 'Customer': {
//         const businessIdForTask = localStorage.getItem('businessId');
//         this.http.getAllData(`Customers/${businessIdForTask}`).subscribe({
//           next: (res: any) => {
//             // ✅ GlobalCustomerId و CustomerName → نحولها لـ { id, name }
//             const options: AssignOption[] = (res as any[]).map(c => ({
//               id: String(c.globalCustomerId ?? c.GlobalCustomerId),
//               name: c.customerName ?? c.CustomerName,
//             }));
//             onResult(options);
//             onLoading(false);
//           },
//           error: (err) => {
//             console.error(err);
//             onResult([]);
//             onLoading(false);
//           },
//         });
//         break;
//       }

//       case 'System': {
//         this.http.getAllData('GlobalSystem').subscribe({
//           next: (res: any) => {
//             // ✅ GlobalSystemId و GlobalSystemName → نحولها لـ { id, name }
//             const options: AssignOption[] = (res as any[]).map(s => ({
//               id: String(s.globalSystemId ?? s.GlobalSystemId),
//               name: s.globalSystemName ?? s.GlobalSystemName,
//             }));
//             onResult(options);
//             onLoading(false);
//           },
//           error: (err) => {
//             console.error(err);
//             onResult([]);
//             onLoading(false);
//           },
//         });
//         break;
//       }

//       case 'User': {
//         const businessId = localStorage.getItem('businessId');
//         this.http.getAllData(`Account/getAllUsers/${businessId}`).subscribe({
//           next: (res: any) => {
//             console.log(res)
//             const options: AssignOption[] = (res as any[]).map(s => ({
//               id: s.id ?? s.Id,           // ← يضل string، ما بنحوله لـ number
//               name: s.userName ?? s.UserName,
//             }));
//             onResult(options);
//             onLoading(false);
//             if (this.selectedAssignerId == null) {
//               const currentUserId = localStorage.getItem('userId');
//               console.log(JSON.stringify(localStorage.getItem('userId'))); 
//               console.log(options)
//               const currentUserOption = options.find(opt => opt.id === currentUserId); // === مقارنة string-to-string سليمة
//               console.log(currentUserOption)
//               if (currentUserOption) {
//                 this.selectedAssignerId = currentUserOption.id;
//               }
//             }
//           },
//           error: (err) => {
//             console.error(err);
//             onResult([]);
//             onLoading(false);
//           },
//         });
//         break;
//       }

//       default:
//         console.warn('Unknown assign type:', typeName);
//         onResult([]);
//         onLoading(false);
//         break;
//     }
//   }

//   onAssignerTypeChange(id: number | undefined) {
//     this.selectedAssignerId = undefined;
//     this.assignerOptions = [];
//     this.cdr.detectChanges()
//     const assignerType = this.assignTypes.find(x => x.assign_typeId === id);
//     if (!assignerType) {
//       console.warn('Assigner type not found for id:', id);
//       return;
//     }
//     this.selectedAssignerTypeId = id

//     this.loadOptionsForType(
//       assignerType.type,
//       (state) => { this.loadingAssignerOptions = state; this.cdr.detectChanges(); },
//       (options) => { this.assignerOptions = options; this.cdr.detectChanges(); }
//     );
//     this.cdr.detectChanges()
//   }

//   onAssigneeTypeChange(id: number | undefined) {
//     this.selectedAssigneeId = undefined;
//     this.assigneeOptions = [];


//     const assigneeType = this.assignTypes.find(x => x.assign_typeId === id);
//     if (!assigneeType) {
//       console.warn('Assignee type not found for id:', id);
//       return;
//     }

//     this.selectedAssigneeTypeId = id;

//     this.loadOptionsForType(
//       assigneeType.type,
//       (state) => { this.loadingAssigneeOptions = state; this.cdr.detectChanges(); },
//       (options) => { this.assigneeOptions = options; this.cdr.detectChanges(); }
//     );
//   }

//   addFeature() {
//     this.loading = true;

//     if (!this.notes) {
//       this.message = 'Please enter order notes';
//       this.loading = false;
//       return;
//     }

//     if (!this.selectedBusinessId) {
//       this.message = 'Please select a business';
//       this.loading = false;
//       return;
//     }

//     const payLoad = {
//       Business_id: this.selectedBusinessId,
//       GlobalCustomerId: this.selectedCustomerId,
//       Schedule_dt: this.scheduleDate || null,
//       Schedule_time: this.scheduleTime || null,
//       OrderStatusId: this.selectedOrderStatusId,
//       Notes: this.notes,
//       Service_id: this.selectedServiceId,
//       AssignerTypeId: this.selectedAssignerTypeId,
//       AssignerId: this.selectedAssignerId,
//       AssigneeTypeId: this.selectedAssigneeTypeId,
//       AssigneeId: this.selectedAssigneeId,
//     };

//     console.log(payLoad)

//     this.http.posteData('Orders/AddGlobalOrder', payLoad).subscribe(res => {
//       this.router.navigate(['Home/features']);
//       this.loading = false;
//     }, (error) => {
//       console.error(error);
//       this.loading = false;
//       this.message = 'An error occurred while adding the order';
//     });
//   }

// }