# Import serializer classes from Django REST Framework
from rest_framework import serializers
import re

# Import models to serialize
from .models import Farmer, FarmerCrop, FarmerInventory

# Import serializers from related apps
from AgroAssist_Backend.crops.serializers import CropSerializer


class FarmerValidationMixin:
    def validate_first_name(self, value):
        cleaned_value = value.strip()
        if not cleaned_value:
            raise serializers.ValidationError("First name cannot be empty.")
        return cleaned_value

    def validate_last_name(self, value):
        cleaned_value = value.strip()
        if not cleaned_value:
            raise serializers.ValidationError("Last name cannot be empty.")
        return cleaned_value

    def validate_phone_number(self, value):
        cleaned_value = value.strip()
        digits_only = re.sub(r'\D', '', cleaned_value)
        if len(digits_only) < 10:
            raise serializers.ValidationError("Phone number must contain at least 10 digits.")
        if not re.fullmatch(r'\+?[0-9][0-9\s().-]{8,19}', cleaned_value):
            raise serializers.ValidationError(
                "Phone number can only contain digits, spaces, brackets, dots, dashes, and an optional leading +."
            )
        return cleaned_value


# SERIALIZER 1: FarmerSerializer - Convert Farmer model to/from JSON
class FarmerSerializer(FarmerValidationMixin, serializers.ModelSerializer):
    # Get full name by combining first and last name
    full_name = serializers.SerializerMethodField()  # Custom field for full name
    location = serializers.CharField(source='city', read_only=True)
    
    class Meta:
        model = Farmer
        fields = ['id', 'user', 'first_name', 'last_name', 'full_name', 'email', 'phone_number',
              'location',
                  'address', 'city', 'state', 'postal_code', 'preferred_language', 
                  'land_area_hectares', 'soil_type', 'experience_level', 
                  'farming_notes', 'contact_method', 'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'full_name', 'user', 'location']  # These can't be edited by API
        
        # Add validation rules for fields
        extra_kwargs = {
            'email': {'required': True, 'allow_blank': False},  # Email is required
            'phone_number': {'required': True},  # Phone is required
            'land_area_hectares': {'min_value': 0.1},  # Minimum 0.1 hectare
        }
    
    def get_full_name(self, obj):
        # obj = the Farmer object being serialized
        # Returns "First Last" format
        return f"{obj.first_name} {obj.last_name}"


# SERIALIZER 2: FarmerCropSerializer - Convert FarmerCrop (farmer's crops) to/from JSON
class FarmerCropSerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields that call methods
    crop_name = serializers.SerializerMethodField()  # Show crop name, not just ID
    farmer_name = serializers.SerializerMethodField()  # Show farmer name  
    days_since_planting = serializers.SerializerMethodField()  # Calculate days elapsed
    days_until_harvest = serializers.SerializerMethodField()  # Calculate days remaining
    
    class Meta:
        model = FarmerCrop
        fields = ['id', 'farmer', 'farmer_name', 'crop', 'crop_name', 'planting_date', 
                  'expected_harvest_date', 'status', 'area_allocated_hectares', 
                  'expected_yield_kg', 'days_since_planting', 'days_until_harvest',
                  'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'farmer_name', 'crop_name', 
                           'days_since_planting', 'days_until_harvest']  # Can't edit these
        extra_kwargs = {
            'farmer': {'required': False, 'allow_null': True},
        }
        validators = []

    def validate(self, attrs):
        request = self.context.get('request')
        farmer = attrs.get('farmer')

        if farmer is None and request is not None:
            user = request.user
            if not (user.is_staff or user.is_superuser):
                farmer = getattr(user, 'farmer', None)
                if farmer is None:
                    farmer = Farmer.objects.filter(email__iexact=user.email).first()
                if farmer is not None:
                    attrs['farmer'] = farmer

        farmer = attrs.get('farmer') or getattr(self.instance, 'farmer', None)
        crop = attrs.get('crop') or getattr(self.instance, 'crop', None)
        planting_date = attrs.get('planting_date') or getattr(self.instance, 'planting_date', None)

        if farmer is None:
            raise serializers.ValidationError({'farmer': ['This field is required.']})

        if farmer and crop and planting_date:
            duplicate_qs = FarmerCrop.objects.filter(
                farmer=farmer,
                crop=crop,
                planting_date=planting_date,
            )
            if self.instance is not None:
                duplicate_qs = duplicate_qs.exclude(pk=self.instance.pk)
            if duplicate_qs.exists():
                raise serializers.ValidationError(
                    'This crop is already assigned to the farmer for the same planting date.'
                )

        return attrs
    
    def get_crop_name(self, obj):
        # Returns the crop name
        return obj.crop.name
    
    def get_farmer_name(self, obj):
        # Returns the farmer name
        return f"{obj.farmer.first_name} {obj.farmer.last_name}"
    
    def get_days_since_planting(self, obj):
        # Calculate how many days since farmer planted this crop
        from datetime import datetime
        today = datetime.now().date()  # Get today's date
        days = (today - obj.planting_date).days  # Calculate difference
        return max(0, days)  # Return 0 if negative (hasn't been planted yet)
    
    def get_days_until_harvest(self, obj):
        # Calculate how many days until harvest (if known)
        if not obj.expected_harvest_date:  # If no harvest date set
            return None  # Return None (unknown)
        
        from datetime import datetime
        today = datetime.now().date()  # Get today's date
        days = (obj.expected_harvest_date - today).days  # Calculate difference
        return max(0, days)  # Return 0 if harvest date has passed


# SERIALIZER 3: FarmerInventorySerializer - Convert inventory items to/from JSON
class FarmerInventorySerializer(serializers.ModelSerializer):
    # SerializerMethodField = Custom fields
    farmer_name = serializers.SerializerMethodField()  # Show farmer name
    days_until_expiry = serializers.SerializerMethodField()  # Calculate days until expiry
    is_expired = serializers.SerializerMethodField()  # Check if expired
    
    class Meta:
        model = FarmerInventory
        fields = ['id', 'farmer', 'farmer_name', 'item_name', 'item_type', 'quantity', 'unit',
                  'purchase_date', 'expiry_date', 'days_until_expiry', 'is_expired', 
                  'notes', 'created_at']
        
        read_only_fields = ['created_at', 'farmer_name', 'days_until_expiry', 'is_expired']  # Can't edit
    
    def get_farmer_name(self, obj):
        # Returns the farmer's name
        return f"{obj.farmer.first_name} {obj.farmer.last_name}"
    
    def get_days_until_expiry(self, obj):
        # Calculate days until item expires (if expiry date is set)
        if not obj.expiry_date:  # If no expiry date
            return None  # Return None (doesn't expire)
        
        from datetime import datetime
        today = datetime.now().date()  # Get today's date
        days = (obj.expiry_date - today).days  # Calculate difference
        return days  # Can be negative if already expired
    
    def get_is_expired(self, obj):
        # Check if item has expired
        if not obj.expiry_date:  # If no expiry date
            return False  # Not expired
        
        from datetime import datetime
        today = datetime.now().date()  # Get today's date
        return today > obj.expiry_date  # True if today is after expiry date


# SERIALIZER 4: FarmerDetailSerializer - Show all farmer info with related data
class FarmerDetailSerializer(serializers.ModelSerializer):
    # Nest related serializers to show all data together
    
    full_name = serializers.SerializerMethodField()  # Full name
    farmer_crops = FarmerCropSerializer(many=True, read_only=True)  # All crops this farmer grows
    inventory_items = FarmerInventorySerializer(many=True, read_only=True)  # All inventory items
    
    class Meta:
        model = Farmer
        fields = ['id', 'first_name', 'last_name', 'full_name', 'email', 'phone_number',
                  'address', 'city', 'state', 'postal_code', 'preferred_language',
                  'land_area_hectares', 'soil_type', 'experience_level', 'farming_notes',
                  'contact_method', 'farmer_crops', 'inventory_items', 'created_at', 'updated_at']
        
        read_only_fields = ['created_at', 'updated_at', 'full_name', 'farmer_crops', 'inventory_items']  # Can't edit
    
    def get_full_name(self, obj):
        # Returns full name concatenated
        return f"{obj.first_name} {obj.last_name}"


# SERIALIZER 5: CreateFarmerSerializer - For creating new farmers with validation
class CreateFarmerSerializer(serializers.ModelSerializer):
    # This serializer has stricter validation for creating new farmer accounts
    
    class Meta:
        model = Farmer
        fields = ['first_name', 'last_name', 'email', 'phone_number', 'address', 'city',
                  'state', 'postal_code', 'preferred_language', 'land_area_hectares',
                  'soil_type', 'experience_level']
        
        # Validation rules
        extra_kwargs = {
            'first_name': {'required': True, 'allow_blank': False, 'min_length': 2},  # At least 2 chars
            'last_name': {'required': True, 'allow_blank': False, 'min_length': 2},  # At least 2 chars
            'email': {'required': True, 'allow_blank': False},  # Email required
            'phone_number': {'required': True, 'allow_blank': False, 'min_length': 10},  # At least 10 chars
            'land_area_hectares': {'required': True, 'min_value': 0.1, 'max_value': 1000},  # Between 0.1-1000
            'soil_type': {'required': True},  # Must select
            'experience_level': {'required': True},  # Must select
        }
    
    def validate_first_name(self, value):
        cleaned_value = value.strip()
        if not cleaned_value:
            raise serializers.ValidationError("First name cannot be empty.")
        return cleaned_value

    def validate_last_name(self, value):
        cleaned_value = value.strip()
        if not cleaned_value:
            raise serializers.ValidationError("Last name cannot be empty.")
        return cleaned_value

    def validate_email(self, value):
        # Custom validation for email - check if already exists
        if Farmer.objects.filter(email=value).exists():  # If email already in database
            raise serializers.ValidationError("A farmer with this email already exists.")  # Error message
        return value  # Return email if valid
    
    def validate_phone_number(self, value):
        cleaned_value = value.strip()
        digits_only = re.sub(r'\D', '', cleaned_value)
        if len(digits_only) < 10:
            raise serializers.ValidationError("Phone number must contain at least 10 digits.")
        if not re.fullmatch(r'\+?[0-9][0-9\s().-]{8,19}', cleaned_value):
            raise serializers.ValidationError(
                "Phone number can only contain digits, spaces, brackets, dots, dashes, and an optional leading +."
            )
        # Custom validation for phone - check if already exists
        if Farmer.objects.filter(phone_number=cleaned_value).exists():  # If phone already exists
            raise serializers.ValidationError("A farmer with this phone number already exists.")  # Error message
        return cleaned_value  # Return phone if valid

