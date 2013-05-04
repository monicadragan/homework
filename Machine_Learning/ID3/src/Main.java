import java.io.FileNotFoundException;


public class Main {
	
	public static void main(String[] args) throws FileNotFoundException{
		
		boolean propagare_var_numerice = false;
		boolean var_necunoscute_majoritare = false;
		
		DecisionTree dt = new DecisionTree("atribute1.txt","invatare1.txt", "test1.txt", propagare_var_numerice, var_necunoscute_majoritare);
		//DecisionTree dt = new DecisionTree("atribute2.txt","invatare2.txt", null, propagare_var_numerice, var_necunoscute_majoritare);
		//DecisionTree dt = new DecisionTree("atribute3.txt","invatare3.txt", null, propagare_var_numerice, var_necunoscute_majoritare);
		//DecisionTree dt = new DecisionTree("atribute_ionut.txt","invatare_ionut.txt", "test_ionut.txt", propagare_var_numerice, var_necunoscute_majoritare);
		//DecisionTree dt = new DecisionTree("atribute-house-voting.txt","invatare-house-voting.txt", "test-house-voting.txt", propagare_var_numerice, var_necunoscute_majoritare);
		//DecisionTree dt = new DecisionTree("atribute-color.txt","invatare-color.txt", "test-color.txt", propagare_var_numerice, var_necunoscute_majoritare);

	}

}
