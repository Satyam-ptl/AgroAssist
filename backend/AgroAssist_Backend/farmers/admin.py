from django.contrib import admin
from .models import Farmer, FarmerCrop, FarmerInventory

# Register Farmer model - Farmer accounts
@admin.register(Farmer)
class FarmerAdmin(admin.ModelAdmin):
    list_display = ['first_name', 'last_name', 'phone_number', 'city', 'experience_level']  # Show in list
    list_filter = ['experience_level', 'soil_type', 'city']  # Filters
    search_fields = ['first_name', 'last_name', 'email', 'phone_number']  # Searchable
    readonly_fields = ['created_at', 'updated_at']  # Can't edit timestamps

# Register FarmerCrop model - What crops each farmer grows
@admin.register(FarmerCrop)
class FarmerCropAdmin(admin.ModelAdmin):
    list_display = ['farmer', 'crop', 'planting_date', 'status']  # Show crop records
    list_filter = ['status', 'crop', 'planting_date']  # Filters
    search_fields = ['farmer__first_name', 'crop__name']  # Search
    readonly_fields = ['created_at', 'updated_at']  # Can't edit

# Register FarmerInventory model - Seeds, fertilizer, tools
@admin.register(FarmerInventory)
class FarmerInventoryAdmin(admin.ModelAdmin):
    list_display = ['farmer', 'item_name', 'item_type', 'quantity', 'expiry_date']  # Show inventory
    list_filter = ['item_type', 'expiry_date']  # Filters
    search_fields = ['farmer__first_name', 'item_name']  # Search
    readonly_fields = ['created_at']  # Can't edit creation time
