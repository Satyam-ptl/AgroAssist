from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth_serializers import FarmerRegistrationSerializer, LoginSerializer
from .models import Farmer
from .stateless_token_auth import issue_auth_token


class FarmerRegisterView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = FarmerRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        payload = serializer.save()
        return Response(payload, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = []

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data["payload"], status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        return Response({"detail": "Logged out successfully."}, status=status.HTTP_200_OK)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        farmer = Farmer.objects.filter(email__iexact=user.email).first()
        role = "admin" if (user.is_staff or user.is_superuser) else "farmer"

        payload = {
            "token": issue_auth_token(user),
            "id": user.id,
            "user_id": user.id,
            "username": user.username,
            "role": role,
            "farmer_id": farmer.id if farmer else None,
            "is_staff": user.is_staff,
            "is_superuser": user.is_superuser,
            "full_name": (f"{user.first_name} {user.last_name}".strip() or user.username),
        }
        return Response(payload, status=status.HTTP_200_OK)
