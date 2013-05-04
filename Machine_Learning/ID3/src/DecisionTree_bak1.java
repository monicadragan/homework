/*
import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Scanner;
import java.util.StringTokenizer;


class attribute{
	
	String name;
	String type;
	ArrayList<String> values;
	double mean; // mean value for numeric attributes
	double informational_gain;
	
	attribute(attribute a){
		name = a.name;
		type = a.type;
		values = new ArrayList<String>(a.values);		
		mean = a.mean;
		informational_gain = a.informational_gain;		
	}
	
	attribute(){
		values = new ArrayList<String>();
	}
	
}

class pair{

	String name;
	int cnt;
	
	pair(String name, int cnt){
		this.name = name;
		this.cnt = cnt;
	}
}


public class DecisionTree {
	
	class MyComparator implements Comparator< ArrayList<String> >{
		 
		int column;

	    MyComparator(int column){
	    	this.column = column;
	    }
	    
		@Override
		public int compare(ArrayList<String> set1, ArrayList<String> set2) {
			if(set1.get(column).compareTo("?") == 0)
				return 1;
			if(set2.get(column).compareTo("?") == 0)
				return 0;
			if(Integer.parseInt(set1.get(column)) > Integer.parseInt(set2.get(column)))
				return 1;
			return 0;
		}
	}
	
	class Node {
		
		String name;
		String label;
		ArrayList<Node> children;
		boolean numeric = false;
		
		Node(String name, String label){
			children = new ArrayList<Node>();
			this.name = name;
			this.label = label;			
		}
		Node(String name, String label, Node right, Node left){
			children = new ArrayList<Node>();
			this.name = name;
			this.label = label;			
			if(right != null)
				children.add(right);
			if(left != null)
				children.add(right);
		}		
	}
	
	ArrayList<attribute> attributes = new ArrayList<attribute>();
	ArrayList<String> classes = new ArrayList<String>();
	ArrayList< ArrayList<String> > training_set = new ArrayList< ArrayList<String> >();
	ArrayList< ArrayList<String> > test_set = new ArrayList< ArrayList<String> >();
	int training_set_length;
	Node decisionTree;
	
	void readAttributes(File file) throws FileNotFoundException{
		
		Scanner sc = new Scanner(file);
		
		int no_classes = sc.nextInt();		
		sc.nextLine();
		StringTokenizer st = new StringTokenizer(sc.nextLine());
	    while (st.hasMoreTokens()) {
	         classes.add(st.nextToken().toLowerCase());	
	    }
	    
	    int no_attributes = sc.nextInt();
	    sc.nextLine();
	    for(int i=0;i<no_attributes;i++){
			st = new StringTokenizer(sc.nextLine());
			
			attribute attr = new attribute();
			attr.name = st.nextToken().toLowerCase();
			
			String type = st.nextToken().toLowerCase();
			if(type.compareTo("numeric") == 0)
				attr.type = "numeric";
			else{
				attr.type = "discret";
				String no_values = st.nextToken();
				while (st.hasMoreTokens()) {
			         attr.values.add(st.nextToken().toLowerCase());		       
			    }
			}
		    attributes.add(attr);
	    }		
	}
	
	void readTrainingSet(File file) throws FileNotFoundException{
		
		Scanner sc = new Scanner(file);
		
		training_set_length = sc.nextInt();
		sc.nextLine();
		for(int i=0;i<training_set_length;i++){
			//training_set.get(i)  = new ArrayList<String>();
			StringTokenizer st = new StringTokenizer(sc.nextLine());
			ArrayList<String> values = new ArrayList<String>();
			while (st.hasMoreTokens()) {
				values.add(st.nextToken().toLowerCase());		       
		    }
			if(values.get(values.size()-1).compareTo("?") != 0)
				training_set.add(values);
		}
		
		replaceUnknown(training_set, attributes);
		  		
	}
	
	int getNoOfClassesAttr(int idx, String value, String value_class){
		
		int cnt = 0;
		
		int classIdx = training_set.get(0).size()-1; 
		for(int i=0;i<training_set.size();i++)
			if(training_set.get(i).get(idx).compareTo(value) == 0)
				if(training_set.get(i).get(classIdx).compareTo(value_class) == 0)
					cnt++;			
		return cnt;
	}
	
	
	void readTests(File file) throws FileNotFoundException{
		
		Scanner sc = new Scanner(file);
		
		int test_set_length = sc.nextInt();
		sc.nextLine();
		for(int i=0;i<test_set_length;i++){
			StringTokenizer st = new StringTokenizer(sc.nextLine());
			ArrayList<String> values = new ArrayList<String>();
			while (st.hasMoreTokens()) {
				values.add(st.nextToken().toLowerCase());		       
		    }
			test_set.add(values);
		}		
	}
	
	void replaceUnknown(ArrayList<ArrayList<String>> training_set, ArrayList<attribute> attributes){
		
		//inlocuiesc valorile necunoscute
		
		ArrayList<pair> classDistribution = new ArrayList<pair>();
		
		for(int k=0;k<classes.size();k++){
			pair p = new pair(classes.get(k),0);
			classDistribution.add(p);
		}
		    	  
		int classIdx = training_set.get(0).size()-1;
		for(int j=0;j<training_set.size();j++){
        	for(int k=0;k<classes.size();k++){
	       		if(training_set.get(j).get(classIdx).compareTo(classDistribution.get(k).name) == 0)
	       			classDistribution.get(k).cnt++;
        	}		            	
        }
		
		for(int i=0;i<training_set.size();i++){
			for(int j=0;j<attributes.size();j++){
				if(training_set.get(i).get(j).compareTo("?") == 0){
					attribute attr = new attribute(attributes.get(j));
					double p_max = 0;
					String value_max = "";
					if(attr.type.compareTo("discret") == 0){
						String value_class = training_set.get(i).get(classIdx); 
						int p_class = 0;
						for(int k=0;k<classDistribution.size();k++){
							if(classDistribution.get(k).name.compareTo(value_class) == 0){
								p_class = classDistribution.get(k).cnt;
								break;
							}
						}						
						//pentru fiecare valoare a acestui atribut
						for(int k=0;k<attr.values.size();k++){
							String value = attr.values.get(k);
							//cate intrari au atribut = value si clasa = set_class						
							int classesAttr = getNoOfClassesAttr(j, value, value_class);
							double p = (double)classesAttr / p_class;
							if(p_max < p){
								p_max = p;
								value_max = attr.values.get(k);
							}
								
						}						
					}
					else{
						continue;
					}
					training_set.get(i).remove(j);
					training_set.get(i).add(j,value_max);
				}
			}
		}   				
	}
	
	void print_training_set(){
		
		System.out.println("Attributes: ");
		for(int j=0;j<attributes.size();j++){
			System.out.print(attributes.get(j).name+" ");
		}		
		System.out.println("\n");
		
		System.out.println("Classes: ");
		for(int j=0;j<classes.size();j++){
			System.out.print(classes.get(j)+" ");
		}		
		System.out.println("\n");
		
		for(int i=0;i<training_set_length;i++){
			for(int j=0;j<attributes.size()+1;j++){
				System.out.print(training_set.get(i).get(j)+" ");				
			}
			System.out.println();
		}
		System.out.println();
	}
	
	ArrayList<pair> castig_informational(ArrayList<attribute> attributes, ArrayList< ArrayList<String> > training_set){
				
		ArrayList<pair> classes2 = new ArrayList<pair>();
		
		for(int k=0;k<classes.size();k++){
			pair p = new pair(classes.get(k),0);
			classes2.add(p);
		}
		    	    
		for(int j=0;j<training_set.size();j++){
        		for(int k=0;k<classes.size();k++){
	        		if(training_set.get(j).get(training_set.get(j).size()-1).compareTo(classes2.get(k).name) == 0)
	        			classes2.get(k).cnt++;
        		}		            	
        }
		
		double entropy = 0;
		for(int k=0;k<classes2.size();k++){
			entropy -= (double) (((double)classes2.get(k).cnt/training_set.size())*Math.log((double)classes2.get(k).cnt/training_set.size())/Math.log(2));
		}
		    
		//castigul informational pentru fiecare atribut
		for(int i=0;i<attributes.size();i++){
			double gain = entropy - informational_gain_attr(i, attributes, training_set);
			attributes.get(i).informational_gain = gain;			
		}	    
		
		return classes2;
	}
	
	double informational_gain_attr(int attr, ArrayList<attribute> attributes, ArrayList< ArrayList<String> > training_set){
		
		double sum = 0;
		
		ArrayList<pair> values = new ArrayList<pair>();
		ArrayList<pair> classes2 = new ArrayList<pair>();
		
		attribute attribute = attributes.get(attr);
		
		if(attribute.type.compareTo("discret") == 0){
			//atribut cu valori discrete
			
			for(int i=0;i<attribute.values.size();i++){			
				pair p = new pair(attribute.values.get(i),0);
				for(int j=0;j<training_set.size();j++){
					if(training_set.get(j).get(attr).compareTo(p.name) == 0){
						p.cnt++;
					}
				}
				values.add(p);
			}
			
			for(int i=0;i<values.size();i++){	        
				
				classes2.clear();
				for(int k=0;k<classes.size();k++){
					pair p = new pair(classes.get(k),0);
					classes2.add(p);
				}
				
		        for(int j=0;j<training_set.size();j++){
		        	if(training_set.get(j).get(attr).compareTo(values.get(i).name) == 0){	        		
		        		for(int k=0;k<classes2.size();k++){
			        		if(training_set.get(j).get(training_set.get(j).size()-1).compareTo(classes2.get(k).name) == 0)
			        			classes2.get(k).cnt++;
		        		}		    
		        	}
		        }
		        
			    double entropy = 0;
			    for(int k=0;k<classes2.size();k++)
			    	if(classes2.get(k).cnt!=0){
			    		entropy -= (double) (((double)classes2.get(k).cnt/values.get(i).cnt)*Math.log((double)classes2.get(k).cnt/values.get(i).cnt)/Math.log(2));		    
			    	}
	
		        sum += (double)values.get(i).cnt/training_set.size() * entropy;
		    }
			
			return sum;
		}
		else{
			//atribut numeric
			
			//ordonez setul de date dupa atribut
			ArrayList< ArrayList<String> > training_set2 = new ArrayList< ArrayList<String> >();
			
			for(int i=0;i<training_set.size();i++){
				training_set2.add(new ArrayList<String>(training_set.get(i)));
			}
			
			Collections.sort(training_set2, new MyComparator(attr));
			
			int classIdx = training_set2.get(0).size()-1;
			double minGain = 1000;
			double mean = 0;
			
			for(int i=1;i<training_set2.size();i++){
				if(training_set2.get(i-1).get(attr).compareTo("?") != 0){
					//pentru fiecare granita calculez castigul informational
					if(training_set2.get(i).get(classIdx) != training_set2.get(i-1).get(classIdx)){
						ArrayList< ArrayList<String> > training_set_labled = new ArrayList< ArrayList<String> >();
						for(int j=0;j<training_set.size();j++){
							training_set_labled.add(new ArrayList<String>(training_set2.get(j)));
						}
						
						//double local_mean = (double)(Integer.parseInt(training_set2.get(i-1).get(attr))+Integer.parseInt(training_set2.get(i).get(attr)))/2;
						
						for(int j=0;j<training_set.size();j++){
							if(training_set.get(j).get(attr).compareTo("?")!=0){
								//if(Double.parseDouble(training_set.get(j).get(attr)) < local_mean){
								if(j<i){
									training_set_labled.get(j).remove(attr);
									training_set_labled.get(j).add(attr,"label1");
								}
								else{
									training_set_labled.get(j).remove(attr);
									training_set_labled.get(j).add(attr,"label2");
								}
							}
						}
						
						ArrayList<attribute> attributes2 = new ArrayList<attribute> ();
						for(int j=0;j<attributes.size();j++)
							attributes2.add(new attribute(attributes.get(j)));
						
						attribute discrete_attribute = new attribute(attributes.get(attr));
						discrete_attribute.values.clear();
						discrete_attribute.values.add("label1");
						discrete_attribute.values.add("label2");
						discrete_attribute.type = "discret";
						
						attributes2.remove(attr);
						attributes2.add(attr,discrete_attribute);
						
						replaceUnknown(training_set, attributes2);
						
						double gain = informational_gain_attr(attr, attributes2, training_set_labled);					
						if(minGain > gain){
							minGain = gain;
							mean = (double)(Integer.parseInt(training_set2.get(i-1).get(attr))+Integer.parseInt(training_set2.get(i).get(attr)))/2;
						}
					}
				}
			}
			
			attributes.get(attr).mean = mean;
			return minGain;			
		}		
	}	
	
	Node createDecisionTree(int indentare, ArrayList<attribute> attributes, ArrayList< ArrayList<String> > training_set, String print){
		
        //ArrayList< ArrayList<String> > old_training_set = new ArrayList< ArrayList<String> >();
        //for(int i=0;i<training_set.size();i++)
        //	old_training_set.add(training_set.get(i));
        
        ArrayList<pair> classes2 = castig_informational(attributes, training_set);        
        
		//for(int i=0;i<indentare;i++)
		//	System.out.print("\t\t");
		
		//if(print != null)
		//	System.out.print("--"+print+"-- ");
        
		//daca toate exemplele sunt din aceeasi clasa		
		for(int k=0;k<classes2.size();k++)
			if(classes2.get(k).cnt == training_set.size()){
				//System.out.println(classes2.get(k).name);
				return new Node(classes2.get(k).name,print,null,null);
			}
		
		//daca nu mai exista atribute
		if(attributes.size() == 0){				    
			int max = 0;
			String default_class = "";
			for(int k=0;k<classes2.size();k++)
				if(classes2.get(k).cnt > max){
					max = classes2.get(k).cnt;
					default_class = classes2.get(k).name;
				}		
			//System.out.println(default_class);
			return new Node(default_class, print, null, null);
		}
		
		//altfel
	    int attr_max = 0;
	    double max = 0;
	    
	    for(int i=0;i<attributes.size();i++){
	    	double a = attributes.get(i).informational_gain;
	    	if(attributes.get(i).informational_gain > max){
	    		max = attributes.get(i).informational_gain;
	    		attr_max = i;
	    	}
	    }
	  
	    //System.out.println(attributes.get(attr_max).name);	
	    Node node = new Node(attributes.get(attr_max).name,print,null,null);
		
	    if(attributes.get(attr_max).type.compareTo("discret") == 0){
			for(int i=0;i<attributes.get(attr_max).values.size();i++){			
				String value = attributes.get(attr_max).values.get(i);				
		        ArrayList< ArrayList<String> > subset = new ArrayList< ArrayList<String> >();
		        
		        for(int j=0;j<training_set.size();j++){
		        	if(training_set.get(j).get(attr_max).compareTo(value) == 0){ 
		        		subset.add(new ArrayList<String>(training_set.get(j)));
		        		subset.get(subset.size()-1).remove(attr_max);	        		
		        	}
		        }
		        ArrayList<attribute> attributes2 = new ArrayList<attribute>(attributes);
		        attributes2.remove(attr_max);
		        node.children.add(createDecisionTree(indentare+1, attributes2, subset, value));
		    }	
	    }
	    else{
	    	node.numeric = true;
	    	
	    	double mean = attributes.get(attr_max).mean;
	    	//lower part	    	
			String value = "<=" + attributes.get(attr_max).mean;				
	        ArrayList< ArrayList<String> > lower_subset = new ArrayList< ArrayList<String> >();
	        
	        for(int j=0;j<training_set.size();j++){
	        	if(Double.parseDouble(training_set.get(j).get(attr_max)) <= mean){ 
	        	//if(training_set.get(j).get(attr_max).compareTo("label1") == 0){
	        		lower_subset.add(new ArrayList<String>(training_set.get(j)));
	        		lower_subset.get(lower_subset.size()-1).remove(attr_max);	        		
	        	}
	        }
	        ArrayList<attribute> lower_attributes = new ArrayList<attribute>(attributes);
	        lower_attributes.remove(attr_max);
	        node.children.add(createDecisionTree(indentare+1, lower_attributes, lower_subset, value));
	    	
	    	//higher part
			value = ">"+attributes.get(attr_max).mean;				
	        ArrayList< ArrayList<String> > upper_subset = new ArrayList< ArrayList<String> >();
	        
	        for(int j=0;j<training_set.size();j++){
	        	if(Double.parseDouble(training_set.get(j).get(attr_max)) > mean){
	        	//if(training_set.get(j).get(attr_max).compareTo("label2") == 0){
	        		upper_subset.add(new ArrayList<String>(training_set.get(j)));
	        		upper_subset.get(upper_subset.size()-1).remove(attr_max);	        		
	        	}
	        }
	        ArrayList<attribute> upper_attributes = new ArrayList<attribute>(attributes);
	        upper_attributes.remove(attr_max);
	        node.children.add(createDecisionTree(indentare+1, upper_attributes, upper_subset, value));	    	        	       
	    }
	    return node;
	}	
	
	int getAttributeIdx(String attr){
		for(int i=0;i<attributes.size();i++){
			if(attributes.get(i).name.compareTo(attr) == 0){
				return i;
			}
		}
		return -1;
	}
	
	String evaluate(ArrayList<String> entry, Node node){
		
		if(node.children.size() == 0)
			return node.name;
		
		int idx = getAttributeIdx(node.name);
		String value = entry.get(idx);
		for(int i=0; i<node.children.size(); i++){
			if(node.numeric){
				if(node.children.get(i).label.charAt(0) == '>'){
					if(Double.parseDouble(value) > Double.parseDouble(node.children.get(i).label.substring(2)))
						return evaluate(entry,node.children.get(i));
				}
				else{
					if(Double.parseDouble(value) <= Double.parseDouble(node.children.get(i).label.substring(2)))
						return evaluate(entry,node.children.get(i));
				}
			}
			if(node.children.get(i).label.compareTo(value) == 0){
				return evaluate(entry,node.children.get(i));
			}
		}
		
		return null;
		
	}
	
	void printTree(Node node, int indentare){
		if(node != null){
			for(int i=0;i<indentare;i++)
				System.out.print("\t\t");
			
			if(node.label != null)
				System.out.print("--"+node.label+"-- ");
			
			System.out.println(node.name);
			
			for(int i=0;i<node.children.size();i++){
				printTree(node.children.get(i),indentare+1);
			}
		}			
	}
	
	DecisionTree(String attributesFile, String trainingFile, String testFile) throws FileNotFoundException{
		if(attributesFile != null)
			readAttributes(new File(attributesFile));
		if(trainingFile != null)
			readTrainingSet(new File(trainingFile));
		if(testFile != null)
			readTests(new File(testFile));
		print_training_set();
		
		decisionTree = createDecisionTree(0, attributes, training_set, null);
		printTree(decisionTree,0);
		
		for(int i=0;i<test_set.size();i++){
			System.out.println(evaluate(test_set.get(i), decisionTree));
		}
			
		
	}
}
*/
