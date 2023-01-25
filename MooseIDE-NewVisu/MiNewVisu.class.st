Class {
	#name : #MiNewVisu,
	#superclass : #MiAbstractVisualization,
	#instVars : [
		'builder'
	],
	#category : #'MooseIDE-NewVisu'
}

{ #category : #highlighting }
MiNewVisu >> highlightShapes [
	

	
]

{ #category : #accessing }
MiNewVisu >> model [

	^ self owner model
]

{ #category : #highlighting }
MiNewVisu >> run [

	| description |
	(description := MiNVVerticalLayoutNode new)
		add: (MiNVBoxNode new
				 name: 'Shared';
				 layout: (MiNVFlowLayoutNode new
						  addAll: ((0 to: 99) collect: [ :i | 
									   MiNVElement new
										   model: i;
										   yourself ]);
						  yourself);
				 yourself);
		add: (MiNVHorizontalLayoutNode new
				 add: (MiNVBoxNode new
						  name: 'Client';
						  layout: (MiNVHorizontalLayoutNode new
								   add: (MiNVFlowLayoutNode new
										    addAll: ((100 to: 199) collect: [ :i | 
													     MiNVElement new
														     model: i;
														     yourself ]);
										    yourself);
								   add: (MiNVVerticalLayoutNode new
										    addAll: ((100 to: 120) collect: [ :i | 
													     MiNVElement new
														     model: i;
														     yourself ]);
										    yourself);
								   yourself);
						  yourself);
				 add: (MiNVBoxNode new
						  name: 'Server';
						  layout: (MiNVHorizontalLayoutNode new
								   add: (MiNVVerticalLayoutNode new
										    addAll: ((100 to: 120) collect: [ :i | 
													     MiNVElement new
														     model: i;
														     yourself ]);
										    yourself);
								   add: (MiNVFlowLayoutNode new
										    addAll: ((100 to: 199) collect: [ :i | 
													     MiNVElement new
														     model: i;
														     yourself ]);
										    yourself);
								   yourself);
						  yourself);
				 yourself);
		add: (MiNVBoxNode new
				 name: 'All other classes';
				 layout: (MiNVFlowLayoutNode new
						  addAll: ((0 to: 99) collect: [ :i | 
									   MiNVElement new
										   model: i;
										   yourself ]);
						  yourself);
				 yourself).


	super run.

	builder := MiNewVisuBuilder new
		           mapModel: self model;
		           container: self canvas;
		           yourself.


	builder visit: description
]
