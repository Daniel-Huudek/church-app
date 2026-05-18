import { View, Text, TextInput, TouchableOpacity, StyleSheet, Switch, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { useState } from 'react';
import { prayersService } from '../../../services/prayers';

export default function CreatePrayerScreen() {
  const router = useRouter();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [isUrgent, setIsUrgent] = useState(false);
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [saving, setSaving] = useState(false);

  const handleSubmit = async () => {
    if (!title.trim() || !content.trim()) {
      Alert.alert('Erro', 'Preencha título e conteúdo');
      return;
    }
    setSaving(true);
    try {
      await prayersService.create({ title, content, isUrgent, isAnonymous });
      Alert.alert('Sucesso', 'Pedido de oração criado!');
      router.back();
    } catch (err) {
      Alert.alert('Erro', 'Não foi possível criar o pedido');
    } finally {
      setSaving(false);
    }
  };

  return (
    <View style={styles.container}>
      <TextInput style={styles.input} placeholder="Título" value={title} onChangeText={setTitle} />
      <TextInput style={[styles.input, styles.contentInput]} placeholder="Digite seu pedido de oração..." value={content} onChangeText={setContent} multiline />

      <View style={styles.switchRow}>
        <Text>Urgente</Text>
        <Switch value={isUrgent} onValueChange={setIsUrgent} />
      </View>
      <View style={styles.switchRow}>
        <Text>Anônimo</Text>
        <Switch value={isAnonymous} onValueChange={setIsAnonymous} />
      </View>

      <TouchableOpacity style={styles.button} onPress={handleSubmit} disabled={saving}>
        <Text style={styles.buttonText}>{saving ? 'Enviando...' : 'Enviar Pedido'}</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f5f5', padding: 16 },
  input: { backgroundColor: '#fff', borderRadius: 8, padding: 12, fontSize: 16, marginBottom: 12 },
  contentInput: { height: 150, textAlignVertical: 'top' },
  switchRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#fff', padding: 12, borderRadius: 8, marginBottom: 8 },
  button: { backgroundColor: '#1a73e8', borderRadius: 8, padding: 16, alignItems: 'center', marginTop: 16 },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '600' },
});
