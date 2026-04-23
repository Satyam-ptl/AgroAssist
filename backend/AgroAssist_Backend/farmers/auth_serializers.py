from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Farmer
from .stateless_token_auth import issue_auth_token


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        username = attrs.get("username", "").strip()
        password = attrs.get("password", "")

        user = authenticate(username=username, password=password)
        if not user:
            raise serializers.ValidationError("Invalid username or password.")
        if not user.is_active:
            raise serializers.ValidationError("User account is inactive.")

        token = issue_auth_token(user)
        farmer = Farmer.objects.filter(email__iexact=user.email).first()
        role = "admin" if (user.is_staff or user.is_superuser) else "farmer"

        attrs["payload"] = {
            "token": token,
            "user_id": user.id,
            "username": user.username,
            "role": role,
            "farmer_id": farmer.id if farmer else None,
            "full_name": (f"{user.first_name} {user.last_name}".strip() or user.username),
            "is_staff": user.is_staff,
            "is_superuser": user.is_superuser,
        }
        return attrs


class FarmerRegistrationSerializer(serializers.Serializer):
    username = serializers.CharField(min_length=4, max_length=150)
    password = serializers.CharField(write_only=True, min_length=6)
    first_name = serializers.CharField(min_length=2, max_length=100)
    last_name = serializers.CharField(min_length=2, max_length=100, required=False, allow_blank=True, default='')
    email = serializers.EmailField()
    phone_number = serializers.CharField(min_length=10, max_length=20)
    address = serializers.CharField(required=False, allow_blank=True, default='Not provided')
    city = serializers.CharField(max_length=100, required=False, allow_blank=True, default='Unknown')
    state = serializers.CharField(max_length=100, required=False, allow_blank=True, default='Unknown')
    postal_code = serializers.IntegerField(required=False, default=100000)
    preferred_language = serializers.ChoiceField(choices=Farmer.LANGUAGE_CHOICES, required=False, default='English')
    land_area_hectares = serializers.FloatField(min_value=0.1, max_value=1000, required=False, default=1.0)
    soil_type = serializers.ChoiceField(choices=Farmer.SOIL_CHOICES, required=False, default='Loamy')
    experience_level = serializers.ChoiceField(choices=Farmer.EXPERIENCE_CHOICES, required=False, default='Beginner')

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists() or Farmer.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("This email is already registered.")
        return value

    def validate_phone_number(self, value):
        if Farmer.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("This phone number is already registered.")
        return value

    def create(self, validated_data):
        full_name = validated_data["first_name"].strip()
        last_name = (validated_data.get("last_name") or '').strip()

        if not last_name:
            name_parts = full_name.split()
            first_name = name_parts[0]
            last_name = " ".join(name_parts[1:]) if len(name_parts) > 1 else "Farmer"
        else:
            first_name = full_name

        address = (validated_data.get("address") or '').strip() or 'Not provided'
        city = (validated_data.get("city") or '').strip() or 'Unknown'
        state = (validated_data.get("state") or '').strip() or 'Unknown'

        user = User.objects.create_user(
            username=validated_data["username"],
            email=validated_data["email"],
            password=validated_data["password"],
            first_name=first_name,
            last_name=last_name,
            is_staff=False,
            is_superuser=False,
            is_active=True,
        )

        farmer = Farmer.objects.create(
            first_name=first_name,
            last_name=last_name,
            email=validated_data["email"],
            phone_number=validated_data["phone_number"],
            address=address,
            city=city,
            state=state,
            postal_code=validated_data.get("postal_code", 100000),
            preferred_language=validated_data.get("preferred_language", "English"),
            land_area_hectares=validated_data.get("land_area_hectares", 1.0),
            soil_type=validated_data.get("soil_type", "Loamy"),
            experience_level=validated_data.get("experience_level", "Beginner"),
            contact_method="WhatsApp",
        )

        token = issue_auth_token(user)
        return {
            "token": token,
            "user_id": user.id,
            "username": user.username,
            "role": "farmer",
            "farmer_id": farmer.id,
            "full_name": f"{farmer.first_name} {farmer.last_name}",
            "is_staff": user.is_staff,
            "is_superuser": user.is_superuser,
        }
