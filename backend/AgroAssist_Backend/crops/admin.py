from django.contrib import admin
from .models import Crop, CropGuide, CropGrowthStage, CropCareTask, CropRecommendation

# Register Crop model - Main crop information
@admin.register(Crop)
class CropAdmin(admin.ModelAdmin):
    list_display = ['name', 'season', 'soil_type', 'growth_duration_days']  # Show in list view
    list_filter = ['season', 'soil_type']  # Filter on right sidebar
    search_fields = ['name', 'description']  # Searchable fields
    readonly_fields = ['created_at', 'updated_at']  # Can't edit timestamps

# Register CropGuide model - Growing instructions
@admin.register(CropGuide)
class CropGuideAdmin(admin.ModelAdmin):
    list_display = ['crop', 'watering_days_interval']  # Show in list
    list_filter = ['crop']  # Filter by crop
    search_fields = ['crop__name']  # Search by crop name
    readonly_fields = ['created_at', 'updated_at']  # Can't edit

# Register CropGrowthStage model - Growth phases
@admin.register(CropGrowthStage)
class CropGrowthStageAdmin(admin.ModelAdmin):
    list_display = ['crop', 'stage_number', 'stage_name', 'duration_days']  # Show stages
    list_filter = ['crop']  # Filter by crop
    search_fields = ['crop__name', 'stage_name']  # Search
    ordering = ['crop', 'stage_number']  # Sort by crop and stage order

# Register CropCareTask model - Farming tasks
@admin.register(CropCareTask)
class CropCareTaskAdmin(admin.ModelAdmin):
    list_display = ['crop', 'task_name', 'recommended_dap']  # Show tasks and timing
    list_filter = ['crop']  # Filter by crop
    search_fields = ['crop__name', 'task_name']  # Search
    ordering = ['crop', 'recommended_dap']  # Sort by crop and task order

# Register CropRecommendation model - Crop suggestions
@admin.register(CropRecommendation)
class CropRecommendationAdmin(admin.ModelAdmin):
    list_display = ['crop', 'recommended_season', 'priority_score']  # Show recommendations
    list_filter = ['recommended_season', 'priority_score']  # Filter by season/priority
    search_fields = ['crop__name']  # Search by crop
