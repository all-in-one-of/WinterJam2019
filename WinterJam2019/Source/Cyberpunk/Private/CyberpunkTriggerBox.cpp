// Fill out your copyright notice in the Description page of Project Settings.

#include "CyberpunkTriggerBox.h"

ACyberpunkTriggerBox::ACyberpunkTriggerBox()
{
	// Init box component

	RootComponent->SetMobility(EComponentMobility::Static); // Set mobility to static
	UBoxComponent* BoxComponent = CastChecked<UBoxComponent>(GetRootComponent());
	BoxComponent->SetBoxExtent(FVector(50.0f), false);
	//BoxComponent->LineThickness = 1.5f;
	BoxComponent->ShapeColor = FColor::White;
	BoxComponent->UpdateBodySetup();

	// Init visual asset (cube mesh)

	CubeMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("CubeCollision")); // Create static mesh component
	CubeMesh->SetupAttachment(RootComponent); // Set up attachment
	CubeMesh->SetMobility(EComponentMobility::Static); // Set mobiltiy to static

	// Render properties
	CubeMesh->SetHiddenInGame(true, false);
	CubeMesh->CastShadow = 0;
	CubeMesh->bVisibleInReflectionCaptures = false;
	CubeMesh->bReceivesDecals = false;

	// Collision properties
	CubeMesh->SetGenerateOverlapEvents(false);
	CubeMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	CubeMesh->SetCollisionObjectType(ECollisionChannel::ECC_WorldStatic);
	CubeMesh->SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeVisualAsset(TEXT("/Engine/BasicShapes/Cube.Cube")); // Find engine static mesh cube asset
	if (CubeVisualAsset.Succeeded()) // If we found it
		CubeMesh->SetStaticMesh(CubeVisualAsset.Object); // Then set it


	//ATriggerBox::ATriggerBox();
}

void ACyberpunkTriggerBox::OnConstruction(const FTransform& Transform)
{
	if (CubeMesh != nullptr)
		for (int32 i = 0; i < CubeMesh->GetNumMaterials(); i++) // Override all materials with specified material
			CubeMesh->SetMaterial(i, RenderMaterial);

	ATriggerBox::OnConstruction(Transform);
}

void ACyberpunkTriggerBox::EditorApplyScale(const FVector& DeltaScale, const FVector* PivotLocation, bool bAltDown, bool bShiftDown, bool bCtrlDown)
{
	AActor::EditorApplyScale(DeltaScale, PivotLocation, bAltDown, bShiftDown, bCtrlDown); // Use AActor's method which will respect the hierarchy
}