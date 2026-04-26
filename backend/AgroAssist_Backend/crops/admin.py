from django.contrib import admin
from .models import Crop, CropGuide, CropGrowthStage, CropCareTask, CropRecommendation


@admin.register(Crop)
class CropAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'category', 'crop_type',
        'season', 'soil_type',
        'growth_duration_days', 'states_preview',
    ]
    list_filter = ['season', 'soil_type', 'category', 'crop_type']
    search_fields = ['name', 'description', 'states']
    list_display_links = ['name']
    readonly_fields = ['created_at', 'updated_at']
    list_per_page = 50
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'category', 'crop_type', 'season', 'description')
        }),
        ('Location', {
            'fields': ('states',),
            'description': 'Comma-separated states e.g. Maharashtra,Punjab,Gujarat'
        }),
        ('Soil & Water', {
            'fields': ('soil_type', 'water_required_mm_per_week', 'optimal_soil_moisture')
        }),
        ('Growing Conditions', {
            'fields': ('growth_duration_days', 'optimal_temperature', 'optimal_humidity')
        }),
        ('Yield & Fertilizer', {
            'fields': ('fertilizer_required', 'expected_yield_per_hectare')
        }),
        ('Timestamps', {
            'classes': ('collapse',),
            'fields': ('created_at', 'updated_at'),
        }),
    )

    @admin.display(description='States')
    def states_preview(self, obj):
        if not obj.states:
            return '—'
        states_list = [s.strip() for s in obj.states.split(',') if s.strip()]
        if len(states_list) <= 3:
            return ', '.join(states_list)
        return f"{', '.join(states_list[:3])} +{len(states_list) - 3} more"


@admin.register(CropGuide)
class CropGuideAdmin(admin.ModelAdmin):
    list_display = ['crop', 'watering_days_interval', 'created_at']
    search_fields = ['crop__name']
    readonly_fields = ['created_at', 'updated_at']
    list_per_page = 50
    autocomplete_fields = ['crop']
    fieldsets = (
        ('Crop', {'fields': ('crop',)}),
        ('Sowing & Watering', {
            'fields': ('sowing_instructions', 'watering_schedule', 'watering_days_interval')
        }),
        ('Feeding & Protection', {
            'fields': ('fertilizer_schedule', 'disease_management', 'pest_management')
        }),
        ('Harvest & Storage', {
            'fields': ('harvesting_instructions', 'storage_instructions')
        }),
        ('Timestamps', {
            'classes': ('collapse',),
            'fields': ('created_at', 'updated_at'),
        }),
    )


@admin.register(CropGrowthStage)
class CropGrowthStageAdmin(admin.ModelAdmin):
    list_display = ['crop', 'stage_number', 'stage_name', 'duration_days', 'optimal_temperature']
    search_fields = ['crop__name', 'stage_name']
    ordering = ['crop', 'stage_number']
    list_per_page = 50
    autocomplete_fields = ['crop']
    readonly_fields = ['created_at']
    fieldsets = (
        ('Stage Info', {'fields': ('crop', 'stage_number', 'stage_name', 'duration_days')}),
        ('Optimal Conditions', {
            'fields': ('optimal_temperature', 'optimal_humidity', 'optimal_soil_moisture')
        }),
        ('Instructions', {'fields': ('description', 'care_instructions')}),
        ('Timestamps', {'classes': ('collapse',), 'fields': ('created_at',)}),
    )


@admin.register(CropCareTask)
class CropCareTaskAdmin(admin.ModelAdmin):
    list_display = ['crop', 'task_name', 'recommended_dap', 'frequency']
    search_fields = ['crop__name', 'task_name']
    ordering = ['crop', 'recommended_dap']
    list_per_page = 50
    autocomplete_fields = ['crop']
    readonly_fields = ['created_at']
    fieldsets = (
        ('Task Info', {'fields': ('crop', 'task_name', 'recommended_dap', 'frequency')}),
        ('Details', {'fields': ('description', 'instructions')}),
        ('Timestamps', {'classes': ('collapse',), 'fields': ('created_at',)}),
    )


@admin.register(CropRecommendation)
class CropRecommendationAdmin(admin.ModelAdmin):
    list_display = ['crop', 'recommended_season', 'priority_score', 'created_at']
    list_filter = ['recommended_season']
    search_fields = ['crop__name', 'recommendation_reason']
    ordering = ['-priority_score']
    list_per_page = 50
    autocomplete_fields = ['crop']
    readonly_fields = ['created_at']
    fieldsets = (
        ('Recommendation', {'fields': ('crop', 'recommended_season', 'priority_score')}),
        ('Details', {'fields': ('recommendation_reason',)}),
        ('Timestamps', {'classes': ('collapse',), 'fields': ('created_at',)}),
    )
