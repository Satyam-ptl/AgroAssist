# Import serializer classes from Django REST Framework
# Serializers convert Python model objects to JSON and vice versa
from rest_framework import serializers

# Import models we want to serialize (convert to JSON)
from .models import Crop, CropGuide, CropGrowthStage, CropCareTask, CropRecommendation


# SERIALIZER 1: CropSerializer - Convert Crop model to/from JSON
class CropSerializer(serializers.ModelSerializer):
    # ModelSerializer automatically creates fields based on model

    def validate_name(self, value):
        cleaned_value = value.strip()
        if not cleaned_value:
            raise serializers.ValidationError("Crop name cannot be empty.")
        return cleaned_value

    def validate_season(self, value):
        valid_values = {choice[0] for choice in Crop.SEASON_CHOICES}
        if value not in valid_values:
            raise serializers.ValidationError("Select a valid crop season.")
        return value

    def validate_soil_type(self, value):
        valid_values = {choice[0] for choice in Crop.SOIL_CHOICES}
        if value not in valid_values:
            raise serializers.ValidationError("Select a valid soil type.")
        return value

    def validate_category(self, value):
        valid_values = {choice[0] for choice in Crop.CATEGORY_CHOICES}
        if value not in valid_values:
            raise serializers.ValidationError("Select a valid crop category.")
        return value

    def validate_crop_type(self, value):
        valid_values = {choice[0] for choice in Crop.CROP_TYPE_CHOICES}
        if value not in valid_values:
            raise serializers.ValidationError("Select a valid crop type.")
        return value
    
    class Meta:
        # model = Which model to serialize (convert)
        model = Crop
        
        # fields = Which fields from model to include in JSON
        # '__all__' = Include all fields from the model
        fields = '__all__'
        
        # read_only_fields = Fields that API can't change (like timestamps)
        read_only_fields = ['created_at', 'updated_at']  # can't be edited by API
        
        # help_text = For documentation, explains each field
        extra_kwargs = {
            'name': {'help_text': 'Name of the crop (e.g., Rice, Wheat)'},
            'category': {'help_text': 'Crop category (e.g., Cereal, Pulse, Vegetable)'},
            'crop_type': {'help_text': 'Crop type (e.g., Field, Horticulture)'},
            'season': {'help_text': 'Which season to grow (Kharif/Rabi/Summer)'},
            'soil_type': {'help_text': 'Type of soil needed for this crop'},
        }


# SERIALIZER 2: CropGuideSerializer - Convert CropGuide model to/from JSON
class CropGuideSerializer(serializers.ModelSerializer):
    # This serializer handles the step-by-step growing instructions
    
    # SerializerMethodField = Custom field that calls a method
    # This field shows crop name instead of just crop ID
    crop_name = serializers.SerializerMethodField()  # Shows crop name, not just ID
    
    class Meta:
        model = CropGuide
        fields = ['id', 'crop', 'crop_name', 'sowing_instructions', 'watering_schedule', 
                  'watering_days_interval', 'fertilizer_schedule', 'disease_management', 
                  'pest_management', 'harvesting_instructions', 'storage_instructions', 
                  'created_at', 'updated_at']  # All important fields included
        
        read_only_fields = ['created_at', 'updated_at']  # can't edit timestamps
    
    # Method that gets called to populate crop_name field
    def get_crop_name(self, obj):
        # obj = the CropGuide object being serialized
        # returns the name of the crop this guide is for
        return obj.crop.name  # Get crop name from the linked crop


# SERIALIZER 3: CropGrowthStageSerializer - Convert growth stages to/from JSON
class CropGrowthStageSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom field to show crop name
    crop_name = serializers.SerializerMethodField()  # Shows crop name, not just ID
    
    class Meta:
        model = CropGrowthStage
        fields = ['id', 'crop', 'crop_name', 'stage_name', 'stage_number', 'duration_days',
                  'optimal_temperature', 'optimal_humidity', 'optimal_soil_moisture',
                  'description', 'care_instructions', 'created_at']
        
        read_only_fields = ['created_at']  # can't edit creation time
    
    def get_crop_name(self, obj):
        # Returns the crop name for this growth stage
        return obj.crop.name


# SERIALIZER 4: CropCareTaskSerializer - Convert care tasks to/from JSON
class CropCareTaskSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom field to show crop name
    crop_name = serializers.SerializerMethodField()  # Shows crop name
    
    class Meta:
        model = CropCareTask
        fields = ['id', 'crop', 'crop_name', 'task_name', 'description', 
                  'recommended_dap', 'frequency', 'instructions', 'created_at']
        
        read_only_fields = ['created_at']  # can't edit creation time
    
    def get_crop_name(self, obj):
        # Returns the crop name for this care task
        return obj.crop.name


# SERIALIZER 5: CropRecommendationSerializer - Convert recommendations to/from JSON
class CropRecommendationSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom field to show crop name
    crop_name = serializers.SerializerMethodField()  # Shows crop name
    
    class Meta:
        model = CropRecommendation
        fields = ['id', 'crop', 'crop_name', 'recommended_season', 
                  'recommendation_reason', 'priority_score', 'created_at']
        
        read_only_fields = ['created_at']  # can't edit creation time
    
    def get_crop_name(self, obj):
        # Returns the crop name for this recommendation
        return obj.crop.name


# SERIALIZER 6: CropDetailSerializer - Shows all crop info with related data
class CropDetailSerializer(serializers.ModelSerializer):
    # NestedSerializer = Show related objects inline instead of just IDs
    
    # SerializerMethodField = Custom field for summary
    growth_stages = CropGrowthStageSerializer(many=True, read_only=True)  # Show all growth stages
    care_tasks = CropCareTaskSerializer(many=True, read_only=True)  # Show all care tasks
    guides = CropGuideSerializer(many=True, read_only=True)  # Show all guides
    recommendations = CropRecommendationSerializer(many=True, read_only=True)  # Show all recommendations
    
    class Meta:
        model = Crop
        fields = ['id', 'name', 'category', 'crop_type', 'description', 'season', 'soil_type', 'growth_duration_days',
                  'optimal_temperature', 'optimal_humidity', 'optimal_soil_moisture',
                  'water_required_mm_per_week', 'fertilizer_required', 'expected_yield_per_hectare',
                  'growth_stages', 'care_tasks', 'guides', 'recommendations', 'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'growth_stages', 'care_tasks', 'guides', 'recommendations']
