# Import ViewSet and filtering tools from Django REST Framework
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.exceptions import PermissionDenied, ValidationError
from django.contrib.auth import get_user_model

# Import models and serializers
from .models import Farmer, FarmerCrop, FarmerInventory
from .serializers import (FarmerSerializer, FarmerCropSerializer, FarmerInventorySerializer,
                         FarmerDetailSerializer, CreateFarmerSerializer)


def _linked_farmer_for_user(user):
    farmer = getattr(user, 'farmer', None)
    if farmer is not None:
        return farmer
    return Farmer.objects.filter(email__iexact=user.email).first()


# PAGINATION CLASS - Show 20 results per page
class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20  # 20 farmers per page
    page_size_query_param = 'page_size'  # Allow ?page_size=50
    max_page_size = 100  # Never give more than 100


# VIEWSET 1: FarmerViewSet - API for farmer accounts
class FarmerViewSet(viewsets.ModelViewSet):
    # ModelViewSet = Full CRUD (Create, Read, Update, Delete)
    
    queryset = Farmer.objects.all()  # All farmers
    pagination_class = StandardResultsSetPagination  # Paginate results
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]  # Search & sort
    search_fields = ['first_name', 'last_name', 'email', 'phone_number', 'city']  # Search these
    ordering_fields = ['first_name', 'city', 'created_at', 'experience_level']  # Sort by these
    ordering = ['-created_at']  # Newest farmers first
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action == 'me':
            return [IsAuthenticated()]

        if self.action in [
            'create',
            'update',
            'partial_update',
            'destroy',
            'by_experience',
            'by_soil',
            'by_city',
        ]:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            return Farmer.objects.all()

        farmer = _linked_farmer_for_user(user)
        if farmer:
            return Farmer.objects.filter(id=farmer.id)
        return Farmer.objects.none()
    
    def get_serializer_class(self):
        # Use different serializer based on action (GET uses detailed, POST uses create)
        
        # If creating new farmer, use strict validation serializer
        if self.action == 'create':
            return CreateFarmerSerializer  # Stricter validation
        
        # If getting detailed view (full farmer profile)
        if self.action == 'retrieve':
            return FarmerDetailSerializer  # Shows all related data
        
        # For list/update/delete, use regular serializer
        return FarmerSerializer  # Standard serializer

    def destroy(self, request, *args, **kwargs):
        if not (request.user.is_staff or request.user.is_superuser):
            raise PermissionDenied('Only admin users can delete farmers.')
        return super().destroy(request, *args, **kwargs)

    def perform_destroy(self, instance):
        user_model = get_user_model()
        linked_user = instance.user or user_model.objects.filter(email__iexact=instance.email).first()
        instance.delete()
        if linked_user and not linked_user.is_superuser:
            linked_user.delete()

    @action(detail=False, methods=['get', 'patch'])
    def me(self, request):
        farmer = _linked_farmer_for_user(request.user)
        if not farmer:
            return Response({'detail': 'No farmer profile found for this user.'}, status=status.HTTP_404_NOT_FOUND)

        if request.method == 'GET':
            serializer = FarmerSerializer(farmer)
            payload = serializer.data
            payload['location'] = payload.get('city', '')
            return Response(payload)

        allowed_fields = {'phone_number', 'phone', 'location'}
        incoming = set(request.data.keys())
        invalid_fields = incoming - allowed_fields
        if invalid_fields:
            raise ValidationError(
                {'detail': f"Only these fields can be updated: {', '.join(sorted(allowed_fields))}."}
            )

        update_data = {}
        if 'phone_number' in request.data:
            update_data['phone_number'] = request.data.get('phone_number')
        elif 'phone' in request.data:
            update_data['phone_number'] = request.data.get('phone')
        if 'location' in request.data:
            update_data['city'] = request.data.get('location')

        serializer = FarmerSerializer(farmer, data=update_data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        payload = serializer.data
        payload['location'] = payload.get('city', '')
        return Response(payload)
    
    # ACTION: Get farmer by experience level
    @action(detail=False, methods=['get'])  # GET at /farmers/by_experience/
    def by_experience(self, request):
        # Get experience level from URL parameter (?level=Expert)
        level = request.query_params.get('level', None)
        
        if not level:
            return Response(
                {'error': 'level parameter required (Beginner/Intermediate/Expert)'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Filter farmers by experience
        farmers = Farmer.objects.filter(experience_level=level)
        
        # Paginate
        page = self.paginate_queryset(farmers)
        if page is not None:
            serializer = FarmerSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerSerializer(farmers, many=True)
        return Response(serializer.data)
    
    # ACTION: Get farmers by soil type
    @action(detail=False, methods=['get'])  # GET at /farmers/by_soil/
    def by_soil(self, request):
        # Get soil type (?soil=Loamy)
        soil = request.query_params.get('soil', None)
        
        if not soil:
            return Response(
                {'error': 'soil parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Filter farmers by soil type
        farmers = Farmer.objects.filter(soil_type=soil)
        
        page = self.paginate_queryset(farmers)
        if page is not None:
            serializer = FarmerSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerSerializer(farmers, many=True)
        return Response(serializer.data)
    
    # ACTION: Get farmers by location/city
    @action(detail=False, methods=['get'])  # GET at /farmers/by_city/
    def by_city(self, request):
        # Get city (?city=Pune)
        city = request.query_params.get('city', None)
        
        if not city:
            return Response(
                {'error': 'city parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Filter farmers by city
        farmers = Farmer.objects.filter(city__icontains=city)  # Case-insensitive search
        
        page = self.paginate_queryset(farmers)
        if page is not None:
            serializer = FarmerSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerSerializer(farmers, many=True)
        return Response(serializer.data)


# VIEWSET 2: FarmerCropViewSet - API for farmer's crops
class FarmerCropViewSet(viewsets.ModelViewSet):
    # ModelViewSet = Full CRUD
    
    queryset = FarmerCrop.objects.all()  # All farmer crop records
    serializer_class = FarmerCropSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['farmer__first_name', 'crop__name']  # Search by farmer/crop name
    ordering = ['-planting_date']  # Newest plantings first
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in ['update', 'partial_update', 'destroy', 'by_season']:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        queryset = FarmerCrop.objects.all()

        if user.is_staff or user.is_superuser:
            farmer_id = self.request.query_params.get('farmer')
            if farmer_id:
                queryset = queryset.filter(farmer_id=farmer_id)
            return queryset

        farmer = _linked_farmer_for_user(user)
        if not farmer:
            return queryset.none()

        return queryset.filter(farmer=farmer)

    def perform_create(self, serializer):
        user = self.request.user
        if user.is_staff or user.is_superuser:
            serializer.save()
            return

        farmer = _linked_farmer_for_user(user)
        if not farmer:
            raise PermissionDenied('No farmer profile linked to this user.')
        serializer.save(farmer=farmer)
    
    # ACTION: Get current crops for a farmer
    @action(detail=False, methods=['get'])  # GET at /farmer-crops/current/
    def current(self, request):
        crops = self.get_queryset().filter(status='Growing')
        
        page = self.paginate_queryset(crops)
        if page is not None:
            serializer = FarmerCropSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerCropSerializer(crops, many=True)
        return Response(serializer.data)
    
    # ACTION: Get harvested crops for a farmer
    @action(detail=False, methods=['get'])  # GET at /farmer-crops/harvested/
    def harvested(self, request):
        crops = self.get_queryset().filter(status='Harvested')
        
        page = self.paginate_queryset(crops)
        if page is not None:
            serializer = FarmerCropSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerCropSerializer(crops, many=True)
        return Response(serializer.data)
    
    # ACTION: Get crops planted in a season
    @action(detail=False, methods=['get'])  # GET at /farmer-crops/by_season/
    def by_season(self, request):
        # Get season (?season=Kharif)
        season = request.query_params.get('season', None)
        
        if not season:
            return Response(
                {'error': 'season parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get crops of this season
        crops = FarmerCrop.objects.filter(crop__season=season)
        
        page = self.paginate_queryset(crops)
        if page is not None:
            serializer = FarmerCropSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerCropSerializer(crops, many=True)
        return Response(serializer.data)


# VIEWSET 3: FarmerInventoryViewSet - API for inventory management
class FarmerInventoryViewSet(viewsets.ModelViewSet):
    # ModelViewSet = Full CRUD
    
    queryset = FarmerInventory.objects.all()
    serializer_class = FarmerInventorySerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['item_name', 'farmer__first_name']  # Search by item/farmer name
    ordering = ['-created_at']  # Newest items first
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        if self.action in [
            'create',
            'update',
            'partial_update',
            'destroy',
            'by_type',
        ]:
            return [IsAdminUser()]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        queryset = FarmerInventory.objects.all()

        if user.is_staff or user.is_superuser:
            farmer_id = self.request.query_params.get('farmer')
            if farmer_id:
                queryset = queryset.filter(farmer_id=farmer_id)
            return queryset

        farmer = _linked_farmer_for_user(user)
        if not farmer:
            return queryset.none()
        return queryset.filter(farmer=farmer)
    
    # ACTION: Get inventory for a specific farmer
    @action(detail=False, methods=['get'])  # GET at /inventory/for_farmer/
    def for_farmer(self, request):
        inventory = self.get_queryset()
        
        page = self.paginate_queryset(inventory)
        if page is not None:
            serializer = FarmerInventorySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerInventorySerializer(inventory, many=True)
        return Response(serializer.data)
    
    # ACTION: Get items by type (e.g., Seeds, Fertilizer)
    @action(detail=False, methods=['get'])  # GET at /inventory/by_type/
    def by_type(self, request):
        # Get item type (?type=Seeds)
        item_type = request.query_params.get('type', None)
        
        if not item_type:
            return Response(
                {'error': 'type parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get items of this type
        items = FarmerInventory.objects.filter(item_type=item_type)
        
        page = self.paginate_queryset(items)
        if page is not None:
            serializer = FarmerInventorySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerInventorySerializer(items, many=True)
        return Response(serializer.data)
    
    # ACTION: Get expired items only
    @action(detail=False, methods=['get'])  # GET at /inventory/expired/
    def expired(self, request):
        # Get today's date
        from datetime import datetime
        today = datetime.now().date()

        items = self.get_queryset().filter(expiry_date__lt=today)
        
        page = self.paginate_queryset(items)
        if page is not None:
            serializer = FarmerInventorySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerInventorySerializer(items, many=True)
        return Response(serializer.data)
    
    # ACTION: Get items expiring soon (within 30 days)
    @action(detail=False, methods=['get'])  # GET at /inventory/expiring_soon/
    def expiring_soon(self, request):
        from datetime import datetime, timedelta

        # Calculate dates
        today = datetime.now().date()  # Today
        thirty_days_later = today + timedelta(days=30)  # 30 days from now

        items = self.get_queryset().filter(
            expiry_date__gte=today,
            expiry_date__lte=thirty_days_later
        )
        
        page = self.paginate_queryset(items)
        if page is not None:
            serializer = FarmerInventorySerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FarmerInventorySerializer(items, many=True)
        return Response(serializer.data)
