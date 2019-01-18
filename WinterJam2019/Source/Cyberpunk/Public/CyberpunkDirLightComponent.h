// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"

#include "Runtime/CoreUObject/Public/UObject/ConstructorHelpers.h"
#include "Runtime/CoreUObject/Public/UObject/UObjectGlobals.h"
#include "Runtime/Engine/Classes/Components/ActorComponent.h"
#include "Runtime/Engine/Classes/Kismet/KismetMaterialLibrary.h"

#include "Components/DirectionalLightComponent.h"
#include "CyberpunkDirLightComponent.generated.h"

/**
 * 
 */
UCLASS()
class CYBERPUNK_API UCyberpunkDirLightComponent : public UDirectionalLightComponent
{
	GENERATED_BODY()

public:

		UFUNCTION(BlueprintCallable)
		void UpdateParameters();
};
