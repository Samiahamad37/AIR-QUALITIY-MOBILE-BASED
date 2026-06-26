from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, UserProfile


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email',  'location']
        # read_only_fields = ['id', 'is_email_verified']
        extra_kwargs = {
            'password': {'write_only': True},
        }


class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = UserProfile
        fields = ['id', 'user', 'bio', 'avatar', 'age_group', 'health_conditions', 'preferred_units', 'created_at', 'updated_at']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'password_confirm']

    def validate(self, data):
        if data['password'] != data.pop('password_confirm'):
            raise serializers.ValidationError("Passwords must match.")
        return data

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        UserProfile.objects.create(user=user)
        return user


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data['username'], password=data['password'])
        if not user:
            raise serializers.ValidationError("Invalid credentials.")
        data['user'] = user
        return data
