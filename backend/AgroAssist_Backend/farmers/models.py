# Import Django model classes for database
from django.db import models
from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver

# Import Crop model from crops app to link farmers with crops they can grow
from AgroAssist_Backend.crops.models import Crop

# MODEL 1: Farmer - Information about a farmer user
class Farmer(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='farmer',
        null=True,
        blank=True,
    )

    # CharField = Text field with max length (short text data)
    first_name = models.CharField(max_length=100)  # Farmer's first name (e.g., "Rajesh")
    
    last_name = models.CharField(max_length=100)  # Farmer's last name (e.g., "Patil")
    
    # EmailField = Special email field with built-in email validation
    email = models.EmailField(unique=True)  # Farmer's email - must be unique (no duplicates)
    
    # CharField for phone number
    phone_number = models.CharField(max_length=20, unique=True)  # Farmer's phone - must be unique
    
    # TextField = Long text for addresses
    address = models.TextField()  # Full home/farm address
    
    # CharField = City/town name
    city = models.CharField(max_length=100)  # City where farmer lives
    
    # CharField = State/province name
    state = models.CharField(max_length=100)  # State (e.g., "Maharashtra", "Punjab")
    
    # IntegerField = Postal/ZIP code (numbers only)
    postal_code = models.IntegerField()  # Postal code of location
    
    # CharField with choices = Dropdown field with options
    LANGUAGE_CHOICES = [
        ('English', 'English'),  # English language
        ('Hindi', 'à¤¹à¤¿à¤¨à¥à¤¦à¥€'),  # Hindi language
        ('Marathi', 'à¤®à¤°à¤¾à¤ à¥€'),  # Marathi language
    ]
    preferred_language = models.CharField(max_length=20, choices=LANGUAGE_CHOICES, default='English')  # Farmer's language preference
    
    # FloatField = Decimal number for land size
    land_area_hectares = models.FloatField()  # How much land farmer has (in hectares)
    
    # CharField with choices = Dropdown for soil type
    SOIL_CHOICES = [
        ('Clay', 'Clay Soil'),  # Heavy soil that holds water
        ('Sandy', 'Sandy Soil'),  # Light soil that drains fast
        ('Loamy', 'Loamy Soil'),  # Perfect balance soil
        ('Mixed', 'Mixed Soil'),  # Combination of types
    ]
    soil_type = models.CharField(max_length=20, choices=SOIL_CHOICES)  # Type of soil on farmer's land
    
    # CharField with choices = Previous farming experience level
    EXPERIENCE_CHOICES = [
        ('Beginner', 'Beginner (New Farmer)'),  # Just starting
        ('Intermediate', 'Intermediate (2-5 years)'),  # Some experience
        ('Expert', 'Expert (5+ years)'),  # Many years experience
    ]
    experience_level = models.CharField(max_length=20, choices=EXPERIENCE_CHOICES)  # Farmer's experience level
    
    # TextField = Farming notes from farmer
    farming_notes = models.TextField(blank=True)  # Any additional notes farmer wants to remember
    
    # CharField = WhatsApp or preferred contact method
    contact_method = models.CharField(max_length=20, default='WhatsApp')  # How to contact farmer
    
    # DateTimeField = Auto-set when farmer account is created
    created_at = models.DateTimeField(auto_now_add=True)  # When farmer registered
    
    # DateTimeField = Auto-update when farmer info is changed
    updated_at = models.DateTimeField(auto_now=True)  # Last time farmer profile was updated
    
    # Meta class = Configuration for Farmer model
    class Meta:
        verbose_name = "Farmer"  # Display name (singular)
        verbose_name_plural = "Farmers"  # Display name (plural)
        ordering = ['-created_at']  # Show newest farmers first
        indexes = [
            models.Index(fields=['first_name']),
            models.Index(fields=['last_name']),
            models.Index(fields=['city']),
        ]
    
    # __str__ = What text shows when displaying this farmer
    def __str__(self):
        # Shows "Rajesh Patil" when displaying farmer
        return f"{self.first_name} {self.last_name}"


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def link_or_create_farmer_for_user(sender, instance, created, **kwargs):
    if instance.is_staff or instance.is_superuser:
        return

    farmer = Farmer.objects.filter(user=instance).first()
    if farmer:
        if farmer.email.lower() != (instance.email or '').lower() and instance.email:
            farmer.email = instance.email
            farmer.save(update_fields=['email'])
        return

    farmer_by_email = None
    if instance.email:
        farmer_by_email = Farmer.objects.filter(email__iexact=instance.email).first()

    if farmer_by_email:
        farmer_by_email.user = instance
        farmer_by_email.save(update_fields=['user'])
        return

    # Intentionally do not auto-create Farmer here to avoid duplicate profiles
    # when signup/tests create Farmer separately.


# MODEL 2: FarmerCrop - Link between farmers and crops (which crops each farmer grows)
class FarmerCrop(models.Model):
    # ForeignKey = Link to Farmer model (each farmer can have many crops)
    # on_delete=models.CASCADE = Delete farmer's crops if farmer account deleted
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='farmer_crops')  # Which farmer
    
    # ForeignKey = Link to Crop model (each crop can be grown by many farmers)
    crop = models.ForeignKey(Crop, on_delete=models.CASCADE, related_name='farmers_growing_crop')  # Which crop
    
    # DateField = Date when farmer started growing this crop
    planting_date = models.DateField()  # When farmer planted this crop
    
    # DateField = Expected harvest date
    expected_harvest_date = models.DateField(blank=True, null=True)  # When expecting to harvest
    
    # CharField with choices = Current status of the crop
    STATUS_CHOICES = [
        ('Planned', 'Planned'),  # Farmer plans to plant
        ('Growing', 'Growing'),  # Currently growing
        ('Harvested', 'Harvested'),  # Already harvested
        ('Completed', 'Completed'),  # Season complete
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Planned')  # Current status
    
    # FloatField = Area allocated to this crop (in hectares)
    area_allocated_hectares = models.FloatField()  # How much land for this crop
    
    # IntegerField = Expected yield from this crop
    expected_yield_kg = models.IntegerField(blank=True, null=True)  # Expected harvest amount in kg
    
    # DateTimeField = Auto-set when record created
    created_at = models.DateTimeField(auto_now_add=True)
    
    # DateTimeField = Auto-update when record modified
    updated_at = models.DateTimeField(auto_now=True)
    
    # Meta class = Configuration for FarmerCrop model
    class Meta:
        verbose_name = "Farmer Crop"  # Display name (singular)
        verbose_name_plural = "Farmer Crops"  # Display name (plural)
        ordering = ['-planting_date']  # Show recently planted first
        # unique_together = No farmer can have same crop twice at same time
        unique_together = ('farmer', 'crop', 'planting_date')  # Prevent duplicates
        indexes = [
            models.Index(fields=['farmer']),
            models.Index(fields=['status']),
            models.Index(fields=['planting_date']),
        ]
    
    def __str__(self):
        # Shows "Rajesh Patil - Rice (Planted)" when displaying
        return f"{self.farmer.first_name} - {self.crop.name} ({self.status})"


# MODEL 3: FarmerInventory - Track farmer's seeds, fertilizer, tools, etc.
class FarmerInventory(models.Model):
    # ForeignKey = Link to Farmer model (each farmer has inventory)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name='inventory_items')  # Which farmer
    
    # CharField = Name of item in inventory
    item_name = models.CharField(max_length=100)  # e.g., "Rice Seeds", "NPK Fertilizer", "Water Pump"
    
    # CharField = Type/category of item
    ITEM_TYPE_CHOICES = [
        ('Seeds', 'Seeds'),  # Crop seeds
        ('Fertilizer', 'Fertilizer'),  # Plant nutrients
        ('Pesticide', 'Pesticide'),  # Pest control
        ('Tools', 'Tools'),  # Farm tools
        ('Water', 'Water'),  # Water resources
        ('Other', 'Other'),  # Anything else
    ]
    item_type = models.CharField(max_length=20, choices=ITEM_TYPE_CHOICES)  # Category of item
    
    # FloatField = Amount farmer has
    quantity = models.FloatField()  # How much of this item farmer has
    
    # CharField = Unit of measurement
    unit = models.CharField(max_length=20, default='kg')  # Units (kg, liters, pieces, etc.)
    
    # DateField = When purchased/acquired
    purchase_date = models.DateField(blank=True, null=True)  # When farmer got this item
    
    # DateField = When this item expires (for seeds, pesticides)
    expiry_date = models.DateField(blank=True, null=True)  # Expiration date if applicable
    
    # TextField = Additional notes about this item
    notes = models.TextField(blank=True)  # Any notes farmer wants to keep about this item
    
    # DateTimeField = Auto-set when item added
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Farmer Inventory"  # Display name (singular)
        verbose_name_plural = "Farmer Inventory"  # Display name (plural)
        ordering = ['-created_at']  # Show newest items first
        indexes = [
            models.Index(fields=['farmer']),
            models.Index(fields=['item_type']),
            models.Index(fields=['expiry_date']),
        ]
    
    def __str__(self):
        # Shows "Rajesh Patil - Rice Seeds (50 kg)" when displaying
        return f"{self.farmer.first_name} - {self.item_name} ({self.quantity} {self.unit})"

