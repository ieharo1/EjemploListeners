/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package ejemplolisteners;
import java.awt.BorderLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;

/**
 *
 * @author Scrappy Doo Coco
 */
public class EjemploListeners {

    /**
     * @param args the command line arguments
     */
    private JPanel panel;
    private JLabel label;

    public EjemploListeners(){
        panel = new JPanel();
        label = new JLabel(" ");
        ActionListener listener = new MyActionListener();

        JButton buttonA = new JButton("Press me A");
        buttonA.setActionCommand("A");
        buttonA.addActionListener(listener);

        JButton buttonB = new JButton("Press me B");
        buttonB.setActionCommand("B");
        buttonB.addActionListener(listener);

        JButton buttonC = new JButton("Press me C");
        buttonC.setActionCommand("C");
        buttonC.addActionListener(listener);

        panel.add(buttonA);
        panel.add(buttonB);
        panel.add(buttonC);
    }
    //Clase que implementa la interfaz del listener
    private class MyActionListener implements ActionListener{

        public void actionPerformed(ActionEvent e) {
            String text = (label.getText() == null || label.getText().isEmpty() )?"":label.getText();
            label.setText(text+e.getActionCommand());           
        }
    }
    private static void createAndShowGUI() {
    
        JFrame frame = new JFrame("Ejemplo Listeners");

        EjemploListeners buttonExample =new EjemploListeners();
        frame.add(buttonExample.panel,BorderLayout.CENTER);
        frame.add(buttonExample.label,BorderLayout.NORTH);

      
        frame.pack();//Hace que la ventana adquiera un tamaño pequeño en la interfaz
        frame.setVisible(Boolean.TRUE);//Hacemos visible al JFrame
    }

    public static void main(String[] args) {
       createAndShowGUI();
    }
    
}
    
    

