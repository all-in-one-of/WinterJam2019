// Fill out your copyright notice in the Description page of Project Settings.

#include "CyberpunkDirLightComponent.h"

void UCyberpunkDirLightComponent::UpdateParameters()
{
	/*
	
	//static ConstructorHelpers::FObjectFinder<UMaterialParameterCollection> LightParamCollection(TEXT("/Game/Art/Shaders/ParameterCollections/Lighting_SPC"));
	//if (LightParamCollection.Succeeded())
	//{

	FString CollectionName = "/Game/Art/Shaders/ParameterCollections/Lighting_SPC";
	UMaterialParameterCollection* LightParamCollection = Cast<UMaterialParameterCollection>(StaticLoadObject(UMaterialParameterCollection::StaticClass(), NULL, *CollectionName));

		UKismetMaterialLibrary::SetVectorParameterValue(this, LightParamCollection, FName(TEXT("Light Direction")), FLinearColor(GetForwardVector()));

		// Calculate colour
		FLinearColor MyLightColour = GetLightColor() * Intensity;
		float MyLightIntensity;
		FVector NullRef;
		FVector(MyLightColour).ToDirectionAndLength(NullRef, MyLightIntensity); // Get length of vector for light intensity
		MyLightColour.A = MyLightIntensity;

		UKismetMaterialLibrary::SetVectorParameterValue(this, LightParamCollection, FName(TEXT("Light Direction")), MyLightColour);
	//}

	*/
}