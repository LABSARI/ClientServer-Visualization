"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestMooseIDENewVisu,
	#superclass : #PackageManifest,
	#category : #'MooseIDE-NewVisu-Manifest'
}

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleCollectionProtocolRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#MiNewVisuBuilder #clients #false)) #'2022-11-24T12:37:23.330758+01:00') )
]

{ #category : #'code-critics' }
ManifestMooseIDENewVisu class >> ruleLongMethodsRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#MiNewVisuBuilder #buildShapes #false)) #'2023-01-16T14:28:25.213065+01:00') )
]
