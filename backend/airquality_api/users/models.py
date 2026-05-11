from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import EmailValidator


class User(AbstractUser):
    """Extended user model with additional fields."""
    email = models.EmailField(unique=True, validators=[EmailValidator()])
    phone = models.CharField(max_length=20, blank=True, null=True)
    location = models.CharField(max_length=255, blank=True, null=True)
    is_email_verified = models.BooleanField(default=False)
    notification_preference = models.CharField(
        max_length=20,
        choices=[
            ('all', 'All Notifications'),
            ('critical', 'Critical Only'),
            ('none', 'No Notifications'),
        ],
        default='all'
    )
    aqi_threshold = models.IntegerField(default=100)  # Alert threshold
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'User'
        verbose_name_plural = 'Users'

    def __str__(self):
        return f"{self.username} ({self.email})"


class UserProfile(models.Model):
    """Additional user profile information."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(blank=True, null=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    age_group = models.CharField(
        max_length=20,
        choices=[
            ('child', 'Child (0-12)'),
            ('teen', 'Teen (13-19)'),
            ('adult', 'Adult (20-59)'),
            ('senior', 'Senior (60+)'),
        ],
        blank=True,
        null=True
    )
    health_conditions = models.JSONField(default=list, blank=True)
    preferred_units = models.CharField(
        max_length=10,
        choices=[
            ('metric', 'Metric (μg/m³)'),
            ('imperial', 'Imperial (ppb)'),
        ],
        default='metric'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profile of {self.user.username}"
