// Fill out your copyright notice in the Description page of Project Settings.

#include "FunctionLibrary_CPP.h"

void UFunctionLibrary_CPP::SetSkyLightCubemapAngle(USkyLightComponent* Target, float Angle)
{
	if (Target != nullptr)
	{
		Target->SourceCubemapAngle = Angle;
		//skyLight->Update
	}
}