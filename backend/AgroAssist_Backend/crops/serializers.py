from rest_framework import serializers
from .models import Crop, CropGuide, CropGrowthStage, CropCareTask, CropRecommendation


class CropSerializer(serializers.ModelSerializer):

    def validate_name(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("Crop name cannot be empty.")
        qs = Crop.objects.filter(name__iexact=cleaned)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError(
                f"A crop named '{cleaned}' already exists."
            )
        return cleaned

    def validate_season(self, value):
        valid = {c[0] for c in Crop.SEASON_CHOICES}
        if value not in valid:
            raise serializers.ValidationError("Select a valid season.")
        return value

    def validate_soil_type(self, value):
        valid = {c[0] for c in Crop.SOIL_CHOICES}
        if value not in valid:
            raise serializers.ValidationError("Select a valid soil type.")
        return value

    def validate_category(self, value):
        valid = {c[0] for c in Crop.CATEGORY_CHOICES}
        if value not in valid:
            raise serializers.ValidationError("Select a valid category.")
        return value

    def validate_crop_type(self, value):
        valid = {c[0] for c in Crop.CROP_TYPE_CHOICES}
        if value not in valid:
            raise serializers.ValidationError("Select a valid crop type.")
        return value

    def validate_states(self, value):
        if not value:
            return ''
        parts = [s.strip() for s in value.split(',') if s.strip()]
        if not parts:
            return ''
        return ','.join(parts)

    def validate_growth_duration_days(self, value):
        if value <= 0:
            raise serializers.ValidationError(
                "Growth duration must be greater than 0."
            )
        return value

    def validate_optimal_temperature(self, value):
        if value < 0 or value > 60:
            raise serializers.ValidationError(
                "Temperature must be between 0 and 60C."
            )
        return value

    def validate_optimal_humidity(self, value):
        if value < 0 or value > 100:
            raise serializers.ValidationError(
                "Humidity must be between 0 and 100%."
            )
        return value

    def validate_optimal_soil_moisture(self, value):
        if value < 0 or value > 100:
            raise serializers.ValidationError(
                "Soil moisture must be between 0 and 100%."
            )
        return value

    class Meta:
        model = Crop
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']
        extra_kwargs = {
            'name': {'help_text': 'Crop name e.g. Rice, Wheat'},
            'category': {'help_text': 'Crop category e.g. Cereal, Pulse'},
            'crop_type': {'help_text': 'Crop type e.g. Field, Horticulture'},
            'season': {'help_text': 'Season: Kharif / Rabi / Summer'},
            'soil_type': {'help_text': 'Soil type needed for this crop'},
            'states': {
                'help_text': 'Comma-separated states e.g. Maharashtra,Punjab,Gujarat',
                'required': False,
            },
        }


class CropGuideSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='crop.name', read_only=True)

    class Meta:
        model = CropGuide
        fields = [
            'id', 'crop', 'crop_name',
            'sowing_instructions', 'watering_schedule',
            'watering_days_interval', 'fertilizer_schedule',
            'disease_management', 'pest_management',
            'harvesting_instructions', 'storage_instructions',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at']


class CropGrowthStageSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='crop.name', read_only=True)

    class Meta:
        model = CropGrowthStage
        fields = [
            'id', 'crop', 'crop_name',
            'stage_name', 'stage_number', 'duration_days',
            'optimal_temperature', 'optimal_humidity',
            'optimal_soil_moisture', 'description',
            'care_instructions', 'created_at',
        ]
        read_only_fields = ['created_at']


class CropCareTaskSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='crop.name', read_only=True)

    class Meta:
        model = CropCareTask
        fields = [
            'id', 'crop', 'crop_name',
            'task_name', 'description',
            'recommended_dap', 'frequency',
            'instructions', 'created_at',
        ]
        read_only_fields = ['created_at']


class CropRecommendationSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='crop.name', read_only=True)

    class Meta:
        model = CropRecommendation
        fields = [
            'id', 'crop', 'crop_name',
            'recommended_season', 'recommendation_reason',
            'priority_score', 'created_at',
        ]
        read_only_fields = ['created_at']


class CropDetailSerializer(serializers.ModelSerializer):
    growth_stages = CropGrowthStageSerializer(many=True, read_only=True)
    care_tasks = CropCareTaskSerializer(many=True, read_only=True)
    guides = CropGuideSerializer(many=True, read_only=True)
    recommendations = CropRecommendationSerializer(many=True, read_only=True)
    states_list = serializers.SerializerMethodField()

    def get_states_list(self, obj):
        if not obj.states:
            return []
        return [s.strip() for s in obj.states.split(',') if s.strip()]

    class Meta:
        model = Crop
        fields = [
            'id', 'name', 'category', 'crop_type',
            'description', 'season', 'soil_type',
            'states', 'states_list',
            'growth_duration_days',
            'optimal_temperature', 'optimal_humidity',
            'optimal_soil_moisture', 'water_required_mm_per_week',
            'fertilizer_required', 'expected_yield_per_hectare',
            'growth_stages', 'care_tasks',
            'guides', 'recommendations',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'created_at', 'updated_at',
            'growth_stages', 'care_tasks',
            'guides', 'recommendations',
            'states_list',
        ]
