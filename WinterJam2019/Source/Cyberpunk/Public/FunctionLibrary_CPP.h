// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "Runtime/Engine/Classes/Components/SkyLightComponent.h"

#include "CoreMinimal.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "FunctionLibrary_CPP.generated.h"

/**
 * 
 */
UCLASS()
class CYBERPUNK_API UFunctionLibrary_CPP : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()


	UFUNCTION(BlueprintCallable)
		static void SetSkyLightCubemapAngle(USkyLightComponent* Target, float Angle);
};
